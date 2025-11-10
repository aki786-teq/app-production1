class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    notifications = current_user.notifications.includes(subject: [ :user, :board ]).order(created_at: :desc)
    @pagy, @notifications = pagy(notifications)

    # 未読の通知を既読に更新
    current_user.notifications.where(checked: false).update_all(checked: true)
  end

  def destroy_all
    current_user.notifications.destroy_all
    redirect_to notifications_path, success: "全ての通知を削除しました。"
  end
end
