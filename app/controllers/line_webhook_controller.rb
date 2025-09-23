class LineWebhookController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!, only: [ :disconnect ]

  # LINE Messaging APIからのリクエスト受信と処理
  def callback
    request_body = request.raw_post
    signature = request.env["HTTP_X_LINE_SIGNATURE"]

    # 署名があっているか検証
    unless valid_signature?(request_body, signature)
      Rails.logger.warn("[LINE Webhook] [400 Bad Request] Invalid signature")
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
        # それ以外は無視
      end
    end

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error("[LINE Webhook] [400 Bad Request] JSON parse error: #{e.message}")
    head :bad_request
  rescue => e
    Rails.logger.error("[LINE Webhook] [500 Internal Server Error] Unexpected error: #{e.message}\n#{e.backtrace.join("\n")}")
    head :internal_server_error
  end

  # 連携URLを踏んだときの処理（通知連携のみ）
  def link
    token = params[:token].to_s

    # ログインしていない場合は、ログイン後に連携を完了するようセッションに保存
    unless user_signed_in?
      session[:pending_line_link_token] = token
      redirect_to new_user_session_path, notice: "LINE通知連携の準備が完了しました。ログイン後に連携が完了します。" and return
    end

    # ログイン中のユーザーと受け取ったtokenを使って「LINE通知の連携完了処理」を実行
    result = LineLinkService.complete_link(current_user, token)

    if result[:success]
      redirect_to reminder_settings_path, notice: result[:message]
    else
      redirect_to reminder_settings_path, alert: result[:message]
    end
  end

  # LINE通知連携解除
  def disconnect
    line_account = current_user.oauth_accounts.find_by(provider: "line_messaging")

    if line_account
      messaging_uid = line_account.uid # 削除前にLINEユーザーIDを保持
      ActiveRecord::Base.transaction do
        # LINE Messaging API の連携情報を削除
        line_account.destroy!
        # LINE通知設定を削除
        current_user.line_notification&.destroy!
        # 関連するLINE連携トークンも削除（未使用トークンも含む）
        LineLinkToken.where(messaging_user_id: messaging_uid).destroy_all
      end
      flash[:success] = "LINE通知連携を解除しました。"
    else
      flash[:danger] = "LINE通知連携が見つかりません。"
    end
    redirect_to reminder_settings_path
  rescue ActiveRecord::RecordNotDestroyed => e
    Rails.logger.error("[LINE Disconnect] Failed to disconnect: #{e.message}")
    flash[:danger] = "連携解除に失敗しました。"
    redirect_to reminder_settings_path
  end

  private

  def valid_signature?(body, signature)
    secret = ENV["LINE_CHANNEL_SECRET"]
    hash = OpenSSL::HMAC.digest("sha256", secret, body)
    expected_signature = Base64.strict_encode64(hash)
    ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature.to_s)
  end

  # LINE Messaging API にアクセスできるオブジェクト作成
  def messaging_client
    @messaging_client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV.fetch("LINE_CHANNEL_TOKEN")
    )
  end

  def handle_follow_event(event)
    # フォローしたユーザーの LINEユーザーID を取り出し
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
    message = "通知連携を完了してください。「連携」とメッセージを送ると連携用リンクを再発行できます。\n#{link_url}"

    sent = send_reply_text(reply_token, message)
    send_push_text(messaging_user_id, message) unless sent
  end

  def handle_message_event(event)
    messaging_user_id = event.dig("source", "userId")
    reply_token = event["replyToken"]
    text = event.dig("message", "text").to_s.strip
    return if messaging_user_id.blank?

    # 「連携」のキーワードで再発行
    if text.include?("連携")
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

    if status_code == 200
      true
    else
      Rails.logger.error("[LINE Webhook] Push failed: status=#{status_code} body=#{response_body} headers=#{response_headers.inspect}")
      false
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
