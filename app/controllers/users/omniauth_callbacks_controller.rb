class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [ :google_oauth2 ]

  def google_oauth2
    callback_for(:google_oauth2)
  end

  private

  def callback_for(provider)
    begin
      auth = request.env["omniauth.auth"]
      # ユーザーを検索または作成
      @user = User.find_user_by_google(auth) || User.create_user_for_google!(auth)

      # Google連携が初回かどうか判定
      linked = User.attach_google_oauth!(@user, auth)

      if @user.persisted?
        # ログイン処理
        sign_in @user unless user_signed_in? && current_user == @user

        # 初回連携かどうかでフラッシュ切り替え
        flash[:notice] = linked ? "Google連携が完了しました！" : "ログインしました。"
        redirect_to root_path
      else
        flash[:alert] = "ユーザー情報の保存に失敗しました。"
        redirect_to new_user_registration_url
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Omniauth save error: #{e.message}")
      flash[:alert] = "認証中にエラーが発生しました: #{e.record.errors.full_messages.to_sentence}"
      redirect_to new_user_registration_url
    end
  end
end
