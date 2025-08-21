class LineWebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  # LINE Messaging API Webhook エンドポイント
  def callback
    request_body = request.raw_post
    signature = request.env["HTTP_X_LINE_SIGNATURE"]

    unless valid_signature?(request_body, signature)
      Rails.logger.warn("[LINE Webhook] Invalid signature")
      head :bad_request and return
    end

    events = JSON.parse(request_body)["events"] || []
    events.each do |event|
      case event["type"]
      when "follow"
        handle_follow_event(event)
      when "message"
        handle_message_event(event)
      else
        # no-op
      end
    end

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error("[LINE Webhook] JSON parse error: #{e.message}")
    head :bad_request
  rescue => e
    Rails.logger.error("[LINE Webhook] Unexpected error: #{e.message}\n#{e.backtrace.join("\n")}")
    head :internal_server_error
  end

  # 連携URLを踏んだときの処理（通知連携のみ）
  before_action :authenticate_user!, only: [ :link, :disconnect ]
  def link
    token = params[:token].to_s
    link_token = LineLinkToken.valid_unconsumed.find_by(token: token)

    if link_token.nil?
      redirect_to reminder_settings_path, alert: "❌ 連携用リンクが無効または期限切れです。時間をおいて再度お試しください。" and return
    end

    messaging_uid = link_token.messaging_user_id

    # 既に同じUIDで連携済みならスキップ
    if current_user.oauth_accounts.find_by(provider: "line_messaging", uid: messaging_uid).present?
      link_token.consume!(user: current_user) unless link_token.consumed?
      redirect_to reminder_settings_path, notice: "✅ すでにLINE通知の連携は完了しています。" and return
    end

    # 他ユーザーに紐づいているUIDなら所有権移譲
    foreign_account = OauthAccount.find_by(provider: "line_messaging", uid: messaging_uid)
    if foreign_account.present? && foreign_account.user_id != current_user.id
      ActiveRecord::Base.transaction do
        old_user = foreign_account.user

        # current_user側にline_messagingがある場合は削除（ユニーク制約回避）
        mine = current_user.oauth_accounts.find_by(provider: "line_messaging")
        mine&.destroy!

        # 所有権をcurrent_userに移譲
        foreign_account.update!(user: current_user)

        # 通知設定の整合（所有権移譲時は設定を維持）
        current_user.line_notification_setting
        begin
          old_user.line_notification_setting&.destroy!
        rescue StandardError
          # 旧ユーザーに設定が無い場合などは無視
        end

        link_token.consume!(user: current_user)
      end

      redirect_to reminder_settings_path, notice: "✅ LINE通知の連携を新しいアカウントに移行しました。" and return
    end

    # 既存のline_messaging連携があればUIDを更新、なければ新規作成
    existing = current_user.oauth_accounts.find_by(provider: "line_messaging")
    if existing
      existing.update!(uid: messaging_uid, auth_data: {})
    else
      current_user.oauth_accounts.create!(
        provider: "line_messaging",
        uid: messaging_uid,
        auth_data: {}
      )
    end

    # 通知設定を作成（自動的に有効化される）
    current_user.line_notification_setting

    link_token.consume!(user: current_user)

    redirect_to reminder_settings_path, notice: "✅ LINE通知の連携が完了しました！3日間投稿がない場合に毎朝7時にリマインド通知をお送りします。"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[LINE Link] Failed to link: #{e.message}")
    redirect_to reminder_settings_path, alert: "❌ 連携に失敗しました。時間をおいて再度お試しください。"
  end

  # LINE通知連携解除
  def disconnect
    line_messaging_scope = current_user.oauth_accounts.where(provider: "line_messaging")

    if line_messaging_scope.exists?
      line_messaging_scope.destroy_all
      flash[:success] = "LINE通知連携を解除しました"
    else
      flash[:danger] = "LINE通知連携が見つかりません"
    end

    redirect_to reminder_settings_path
  end

  private

  def valid_signature?(body, signature)
    secret = ENV["LINE_CHANNEL_SECRET"]
    return true if secret.blank? # 環境未設定時は検証スキップ（本番では必ず設定）

    hash = OpenSSL::HMAC.digest("sha256", secret, body)
    expected_signature = Base64.strict_encode64(hash)
    ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature.to_s)
  end

  def messaging_client
    @messaging_client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV.fetch("LINE_CHANNEL_TOKEN")
    )
  end

  def handle_follow_event(event)
    messaging_user_id = event.dig("source", "userId")
    reply_token = event["replyToken"]
    return if messaging_user_id.blank?

    # 連携用トークンを作成
    token = SecureRandom.urlsafe_base64(24)
    LineLinkToken.create!(
      token: token,
      messaging_user_id: messaging_user_id,
      expires_at: 30.minutes.from_now
    )

    # リンクを生成
    link_url = build_link_url(token)

    # 簡易な案内メッセージ
    message = "通知連携を完了してください👇「連携」とメッセージを送ると通知用URLを再発行できます。\n#{link_url}"

    # Replyで案内（確実に配信）。失敗時はPushにフォールバック
    sent = send_reply_text(reply_token, message)
    send_push_text(messaging_user_id, message) unless sent
  end

  def handle_message_event(event)
    messaging_user_id = event.dig("source", "userId")
    reply_token = event["replyToken"]
    text = event.dig("message", "text").to_s.strip
    return if messaging_user_id.blank?

    # 「連携」「link」などのキーワードで再発行
    if text =~ /(連携|link|リンク)/i
      token = SecureRandom.urlsafe_base64(24)
      LineLinkToken.create!(
        token: token,
        messaging_user_id: messaging_user_id,
        expires_at: 30.minutes.from_now
      )

      link_url = build_link_url(token)
      sent = send_reply_text(reply_token, "通知連携用リンクです\n#{link_url}")
      send_push_text(messaging_user_id, "通知連携用リンクです\n#{link_url}") unless sent
    end
  end

  def build_link_url(token)
    base_url = ENV["APP_BASE_URL"] || "https://mainichi-zenkutsu.jp"
    URI.join(base_url, "/line/link?token=#{CGI.escape(token)}").to_s
  end

  def send_push_text(to_user_id, text)
    message = Line::Bot::V2::MessagingApi::TextMessage.new(text: text)
    request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(to: to_user_id, messages: [ message ])
    response_body, status_code, response_headers = messaging_client.push_message_with_http_info(push_message_request: request)

    unless status_code == 200
      Rails.logger.error("[LINE Webhook] Push failed: status=#{status_code} body=#{response_body} headers=#{response_headers.inspect}")
    end
  rescue => e
    Rails.logger.error("[LINE Webhook] Push exception: #{e.message}")
    false
  end

  def send_reply_text(reply_token, text)
    return false if reply_token.blank?
    message = Line::Bot::V2::MessagingApi::TextMessage.new(text: text)
    request = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(reply_token: reply_token, messages: [ message ])
    response_body, status_code, response_headers = messaging_client.reply_message_with_http_info(reply_message_request: request)
    if status_code == 200
      true
    else
      Rails.logger.error("[LINE Webhook] Reply failed: status=#{status_code} body=#{response_body} headers=#{response_headers.inspect}")
      false
    end
  rescue => e
    Rails.logger.error("[LINE Webhook] Reply exception: #{e.message}")
    false
  end
end
