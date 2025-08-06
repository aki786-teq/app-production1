class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:google_oauth2, :line]

  def google_oauth2
    callback_for(:google)
  end

  def line
    callback_for(:line)
  end

  def passthru
    super
  end

  private

  def callback_for(provider)
    begin
      @user = User.from_omniauth(request.env['omniauth.auth'])

      if @user.persisted?
        # LINE認証の場合は、line_idも更新
        if provider == :line && @user.line_id.blank?
          @user.update!(line_id: request.env['omniauth.auth'].uid)
          # LINE通知設定を有効化
          line_notification = @user.line_notification_setting
          line_notification.update!(notification_enabled: true)
        end

        sign_in @user, event: :authentication
        if provider == :line
          redirect_to reminder_settings_path, notice: 'LINE連携が完了しました！'
        else
          redirect_to root_path
        end
        set_flash_message(:notice, :success, kind: provider.to_s.capitalize) if is_navigational_format?
      else
        # アカウント作成に失敗した場合
        session["devise.#{provider}_data"] = request.env['omniauth.auth'].except('extra')
        redirect_to new_user_registration_url, alert: 'アカウントの作成に失敗しました。'
      end

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Omniauth save error: #{e.message}")
      flash[:alert] = "認証中にエラーが発生しました: #{e.record.errors.full_messages.to_sentence}"
      redirect_to new_user_registration_url
    end
  end

  # OmniAuthが認証失敗した時に、裏で自動で呼び出す
  def failure
    flash[:alert] = "認証に失敗しました"
    redirect_to root_path
  end
end