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
    link_token = LineLinkToken.valid_unconsumed.find_by(token: token)
    return unless link_token

    messaging_uid = link_token.messaging_user_id

    # 既に同じUIDで連携済みならスキップ
    if user.oauth_accounts.find_by(provider: "line_messaging", uid: messaging_uid).present?
      link_token.consume!(user: user) unless link_token.consumed?
      flash[:notice] = "すでにLINE通知の連携は完了しています。"
      return
    end

    # 他ユーザーに紐づいているUIDなら所有権移譲
    foreign_account = OauthAccount.find_by(provider: "line_messaging", uid: messaging_uid)
    if foreign_account.present? && foreign_account.user_id != user.id
      ActiveRecord::Base.transaction do
        old_user = foreign_account.user

        # user側にline_messagingがある場合は削除（ユニーク制約回避）
        mine = user.oauth_accounts.find_by(provider: "line_messaging")
        mine&.destroy!

        # 所有権をuserに移譲
        foreign_account.update!(user: user)

        # 通知設定の整合（所有権移譲時は設定を維持）
        user.line_notification_setting
        begin
          old_user.line_notification_setting&.destroy!
        rescue StandardError
          # 旧ユーザーに設定が無い場合などは無視
        end

        link_token.consume!(user: user)
      end

      flash[:notice] = "LINE通知の連携を新しいアカウントに移行しました。"
      return
    end

    # 既存のline_messaging連携があればUIDを更新、なければ新規作成
    existing = user.oauth_accounts.find_by(provider: "line_messaging")
    if existing
      existing.update!(uid: messaging_uid, auth_data: {})
    else
      user.oauth_accounts.create!(
        provider: "line_messaging",
        uid: messaging_uid,
        auth_data: {}
      )
    end

    # 通知設定を作成（自動的に有効化される）
    user.line_notification_setting

    link_token.consume!(user: user)

    flash[:notice] = "LINE通知の連携が完了しました。3日間投稿がない場合に毎朝7時にリマインド通知をお送りします。"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[LINE Link] Failed to link after login: #{e.message}")
    flash[:alert] = "連携に失敗しました。時間をおいて再度お試しください。"
  end
end
