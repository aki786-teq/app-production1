require 'line-bot-api'

class LineInactiveNotifyJob < ApplicationJob
  sidekiq_options retry: 3

  def perform(user_id)
    user = User.find(user_id)

    # LINE連携チェック
    unless user.line_connected?
      Rails.logger.error "ユーザーID: #{user_id} - LINE連携されていません"
      return
    end

    # LINE通知設定チェック
    unless user.line_notifiable?
      Rails.logger.error "ユーザーID: #{user_id} - LINE通知が無効です"
      return
    end

    Rails.logger.info "ユーザーID: #{user_id} - LINE通知処理開始"
    Rails.logger.info "LINE ID: #{user.line_id}"

    message_text = create_inactive_message(user)

    # LINE通知を送信
    send_line_message(message_text, user.line_id)

    # 通知成功時の処理
    record_notification_success(user)
    Rails.logger.info "ユーザーID: #{user_id} - LINE通知送信成功"

  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "ユーザーID: #{user_id} が見つかりません"
  rescue StandardError => e
    Rails.logger.error "ユーザーID: #{user_id} - LINE通知処理中にエラー: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def client
    @client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV.fetch("LINE_CHANNEL_TOKEN")
    )
  end

  def create_inactive_message(user)
    last_post_date = user.last_post_date
    days_inactive = last_post_date ? (Date.current - last_post_date).to_i : "多数"

    "#{user.name}さん、お疲れ様です！\n\n最後の投稿から#{days_inactive}日が経過しています。\n継続は力なり💪今日も一緒に頑張りましょう！"
  end

  def send_line_message(message_text, line_id)
    text_message = Line::Bot::V2::MessagingApi::TextMessage.new(
      text: message_text
    )

    push_request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
      to: line_id,
      messages: [text_message]
    )

    # HTTP情報を含むレスポンスを取得
    _body, status_code, _headers = client.push_message_with_http_info(push_message_request: push_request)

    # エラーハンドリング
    case status_code
    when 200
      Rails.logger.info "LINE通知送信成功: ステータス=#{status_code}"
    when 400..499
      Rails.logger.error "LINE通知送信失敗: ステータス=#{status_code}"
      raise "LINE通知の送信に失敗しました"
    else
      Rails.logger.error "LINE通知送信失敗: ステータス=#{status_code}"
      raise "LINE通知の送信に失敗しました"
    end
  end

  def record_notification_success(user)
    line_setting = user.line_notification_setting
    line_setting.record_notification!
  end
end