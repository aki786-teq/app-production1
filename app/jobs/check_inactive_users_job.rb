class CheckInactiveUsersJob < ApplicationJob
  sidekiq_options retry: false

  def perform
    Rails.logger.info("無投稿ユーザーのチェックを開始します")
    # 3日間投稿していないユーザーを検索
    inactive_users = find_inactive_users(3)
    if inactive_users.empty?
      Rails.logger.info("3日間無投稿のユーザーは存在しません")
      return
    end

    Rails.logger.info("#{inactive_users.count}人のユーザーに通知を送信します")
    inactive_users.each do |user|
      # LINE通知可能かチェック
      unless user.line_notifiable?
        Rails.logger.info("ユーザーID: #{user.id} - LINE IDが未設定")
        next
      end

      # 同日の重複通知を防止
      line_setting = user.line_notification_setting
      unless line_setting.can_notify_today?
        Rails.logger.info("ユーザーID: #{user.id} - 本日既に通知済み")
        next
      end

      # LINE通知ジョブを実行
      LineInactiveNotifyJob.perform_later(user.id)
      Rails.logger.info("ユーザーID: #{user.id} - LINE通知ジョブをキューに追加")

    rescue StandardError => e
      Rails.logger.error("ユーザーID: #{user.id} - LINE通知処理中にエラーが発生: #{e.message}")
      next
    end

    Rails.logger.info("無投稿ユーザーのチェックを完了しました")
  end

  private

  # LINE連携済み&投稿が3日間以上無いユーザーを検索
  def find_inactive_users(days)
    User
      .joins(:oauth_accounts)
      .where(oauth_accounts: { provider: "line_messaging" })
      .where("NOT EXISTS (
             SELECT 1 FROM boards
             WHERE boards.user_id = users.id
               AND boards.created_at >= ?
           )", days.days.ago)
      .distinct
  end
end
