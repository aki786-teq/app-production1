class ReminderSettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @line_notification = current_user.line_notification_setting
  end

  def update
    @line_notification = current_user.line_notification_setting

    if @line_notification.update(notification_params)
      redirect_to reminder_settings_path, notice: "設定を更新しました"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def notification_params
    params.require(:line_notification).permit(:notification_enabled)
  end
end
