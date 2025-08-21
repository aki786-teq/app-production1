class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [ :google_oauth2 ]

  def google_oauth2
    callback_for(:google)
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

    def callback_for(provider)
    begin
      # Googleログインの処理
      @user = User.from_omniauth(request.env["omniauth.auth"])

      if @user.persisted?
        # 既にログインしているユーザーの場合は、自動ログイン処理をスキップ
        if user_signed_in? && current_user == @user
          Rails.logger.info("User already signed in, skipping automatic login")
        else
          # 未ログインユーザーの場合はログイン処理を実行
          sign_in @user
        end

        # リダイレクト先を決定
        if provider == :google_oauth2
          redirect_to root_path, notice: "Google連携が完了しました！"
        else
          redirect_to root_path
        end
      else
        # アカウント作成に失敗した場合
        session["devise.#{provider}_data"] = request.env["omniauth.auth"].except("extra")
        redirect_to new_user_registration_url, alert: "アカウントの作成に失敗しました。"
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
    when "access_denied"
      "認証がキャンセルされました"
    when "invalid_grant"
      "認証が無効です"
    else
      "認証に失敗しました: #{params[:error]}"
    end

    flash[:alert] = error_message
    redirect_to reminder_settings_path
  end
end
