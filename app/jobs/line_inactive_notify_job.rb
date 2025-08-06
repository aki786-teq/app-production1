require 'line/bot'

class LineInactiveNotifyJob < ApplicationJob
  sidekiq_options retry: 3

  def perform(user_id)
    user = User.find(user_id)

    # LINE IDが設定されているかチェック
    unless user.line_id.present?
      Rails.logger.error "ユーザーID: #{user_id} - LINE IDが設定されていません"
      return
    end

    line_bot_client = create_line_bot_client
    message_text = create_inactive_message(user)

    # LINE通知を送信
    response = send_line_message(line_bot_client, message_text, user.line_id)

    if response_success?(response)
      # 通知成功時の処理
      record_notification_success(user)
      Rails.logger.info "ユーザーID: #{user_id} - LINE通知送信成功"
    else
      # 通知失敗時の処理
      Rails.logger.error "ユーザーID: #{user_id} - LINE通知送信失敗: ステータス=#{response.code}, エラー=#{response.body.inspect}"
      raise "LINE通知の送信に失敗しました"
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "ユーザーID: #{user_id} が見つかりません"
  rescue StandardError => e
    Rails.logger.error "ユーザーID: #{user_id} - LINE通知処理中にエラー: #{e.message}"
    raise e
  end

  private

  def create_line_bot_client
    Line::Bot::Client.new do |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    end
  end

  def create_inactive_message(user)
    last_post_date = user.last_post_date
    days_inactive = last_post_date ? (Date.current - last_post_date).to_i : "多数"

    <<~MESSAGE
      #{user.name}さん、お疲れ様です！

      最後の投稿から#{days_inactive}日が経過しています。
      ストレッチの記録はいかがですか？
      継続は力なり💪今日も一緒に頑張りましょう！

      アプリを開く: #{app_url}
    MESSAGE
  end

  def send_line_message(line_bot_client, message_text, line_id)
    message = {
      type: 'text',
      text: message_text
    }
    line_bot_client.push_message(line_id, message)
  end

  def response_success?(response)
    response.code.to_i.between?(200, 299)
  end

  def record_notification_success(user)
    line_setting = user.line_notification_setting
    line_setting.record_notification!
  end

  def app_url
    # アプリのURLを返す（環境に応じて変更）
    ENV.fetch("APP_BASE_URL", "http://localhost:3000")
  end
end