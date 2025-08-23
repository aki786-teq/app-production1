# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    super do |user|
      # ログイン成功後にLINE連携トークンがある場合は処理
      if session[:pending_line_link_token].present?
        token = session[:pending_line_link_token]
        session.delete(:pending_line_link_token)

        # LINE連携処理を実行
        complete_line_link(user, token)

        # 連携完了後はreminder_settingsにリダイレクト
        redirect_to reminder_settings_path and return
      end
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private

  def complete_line_link(user, token)
    result = LineLinkService.complete_link(user, token)

    if result[:success]
      flash[:notice] = result[:message]
    else
      flash[:alert] = result[:message]
    end
  end
end
