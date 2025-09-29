class LineLinkService
  def self.complete_link(user, token)
    # 渡されたトークンが「有効期限内・未使用か」を確認
    link_token = LineLinkToken.valid_unconsumed.find_by(token: token)
    return { success: false, message: "連携用リンクが無効または期限切れです。" } unless link_token

    # 有効なトークンからLINEのユーザーID（messaging_uid）を取り出す
    messaging_uid = link_token.messaging_user_id

    # 既に同じUID（LINE Messaging API のユーザーID）で連携済みならスキップ
    if user.oauth_accounts.find_by(provider: "line_messaging", uid: messaging_uid).present?
      link_token.consume!(user: user) unless link_token.consumed?
      return { success: true, message: "すでにLINE通知の連携は完了しています。" }
    end

    # そのUIDを既に使っている別ユーザーの連携がないか探す
    foreign_account = OauthAccount.find_by(provider: "line_messaging", uid: messaging_uid)
    # 既に別ユーザーが使っている場合
    if foreign_account.present? && foreign_account.user_id != user.id
      ActiveRecord::Base.transaction do
        old_user = foreign_account.user

        # もし現在のuserにline_messagingがあるなら削除
        mine = user.oauth_accounts.find_by(provider: "line_messaging")
        mine&.destroy!

        # 所有権を現在のユーザーに移譲
        foreign_account.update!(user: user)

        # userの通知設定を作成（なければ）
        user.line_notification_setting
        # 古いユーザーの通知設定を削除
        old_user.line_notification&.destroy!

        # トークンを「使用済み」にする
        link_token.consume!(user: user)
      end

      return { success: true, message: "LINE通知の連携を新しいアカウントに移行しました。" }
    end

    # 現在ログインしているユーザー自身のOauthAccountを作成、または更新
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

    { success: true, message: "LINE通知の連携が完了しました。3日間投稿がない場合に毎朝7時にリマインド通知をお送りします。" }
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[LINE Link] Failed to link: #{e.message}")
    { success: false, message: "連携に失敗しました。時間をおいて再度お試しください。" }
  end
end
