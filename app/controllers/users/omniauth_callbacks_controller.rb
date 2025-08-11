class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:google_oauth2, :line]

  def google_oauth2
    callback_for(:google)
  end

  def line
    callback_for(:line)
  end

  def passthru
    # 既にログインしている場合は、リマインダー設定ページにリダイレクト
    if user_signed_in?
      redirect_to reminder_settings_path
    else
      super
    end
  end

  private

    def handle_line_oauth
      Rails.logger.info("Adding LINE OAuthAccount to current user")

      # 同じUIDのOAuthAccountが他のユーザーに存在する場合は削除
      existing_oauth_account = OauthAccount.find_by(provider: 'line', uid: request.env['omniauth.auth'].uid)
      if existing_oauth_account && existing_oauth_account.user != current_user
        existing_oauth_account.destroy!
        Rails.logger.info("LINE連携を他のユーザーから移行しました")
      end

      # 既に同じプロバイダーのOAuthAccountが存在する場合は削除して新しい連携に置き換え
      existing_oauth = current_user.oauth_accounts.find_by(provider: 'line')
      if existing_oauth
        existing_oauth.destroy!
      end

      # 新しいOAuthAccountを作成
      current_user.oauth_accounts.create!(
        provider: 'line',
        uid: request.env['omniauth.auth'].uid,
        auth_data: request.env['omniauth.auth'].to_hash
      )

      current_user
    end

    def callback_for(provider)
    begin
      # LINE連携は通知用のみで、ログインには使用しない
      if provider == :line
        @user = handle_line_oauth
      else
        # Googleログインの場合は通常の処理
        @user = User.from_omniauth(request.env['omniauth.auth'])
      end

      if @user.persisted?
        # 既にログインしているユーザーの場合は、自動ログイン処理をスキップ
        if user_signed_in? && current_user == @user
          Rails.logger.info("User already signed in, skipping automatic login")
        else
          # 未ログインユーザーの場合はログイン処理を実行
          sign_in @user
        end

        # LINE認証の場合は、LINE通知設定を有効化
        if provider == :line
          @user.line_notification_setting.update!(notification_enabled: true)
        end

        # リダイレクト先を決定
        if provider == :line
          redirect_to reminder_settings_path, notice: 'LINE連携が完了しました！'
        elsif provider == :google_oauth2
          redirect_to root_path, notice: 'Google連携が完了しました！'
        else
          redirect_to root_path
        end
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
    Rails.logger.error("OmniAuth failure: #{params.inspect}")

    error_message = case params[:error]
    when 'access_denied'
      '認証がキャンセルされました'
    when 'invalid_grant'
      '認証が無効です'
    else
      "認証に失敗しました: #{params[:error]}"
    end

    flash[:alert] = error_message
    redirect_to reminder_settings_path
  end
end