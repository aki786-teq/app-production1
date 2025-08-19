class LineAuthController < ApplicationController
  before_action :authenticate_user!

  def disconnect
    line_login = current_user.oauth_accounts.find_by(provider: "line")
    line_messaging_scope = current_user.oauth_accounts.where(provider: "line_messaging")

    if line_login || line_messaging_scope.exists?
      ActiveRecord::Base.transaction do
        line_login&.destroy!
        line_messaging_scope.destroy_all
        # LINE通知設定を無効化
        current_user.line_notification_setting&.update!(notification_enabled: false)
      end
      flash[:success] = "LINE連携を解除しました"
    else
      flash[:danger] = "LINE連携が見つかりません"
    end

    redirect_to reminder_settings_path
  end
end
