# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
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
