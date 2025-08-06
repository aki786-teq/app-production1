class LineAuthController < ApplicationController
  before_action :authenticate_user!

  def disconnect
    current_user.update!(line_id: nil)
    # LINE通知設定を無効化
    line_notification = current_user.line_notification_setting
    line_notification.update!(notification_enabled: false)

    redirect_to reminder_settings_path, notice: 'LINE連携を解除しました'
  end
end