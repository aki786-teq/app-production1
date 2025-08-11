class LineAuthController < ApplicationController
  before_action :authenticate_user!

  def disconnect
    oauth_account = current_user.oauth_accounts.find_by(provider: 'line')

    if oauth_account
      oauth_account.destroy!
      # LINE通知設定を無効化
      if current_user.line_notification_setting.present?
        current_user.line_notification_setting.update!(notification_enabled: false)
      end
      flash[:success] = 'LINE連携を解除しました'
    else
      flash[:danger] = 'LINE連携が見つかりません'
    end

    redirect_to reminder_settings_path
  end
end
