class NotificationsController < ApplicationController
  def index
    @pagy, @notifications = pagy(current_user.notifications.order(created_at: :desc))
    current_user.notifications.where(checked: false).update_all(checked: true)
  end

  def destroy_all
    current_user.notifications.destroy_all
    redirect_to notifications_path, success: "通知を全て削除しました。", status: :see_other
  end
end
