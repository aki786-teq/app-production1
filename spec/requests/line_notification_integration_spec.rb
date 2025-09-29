require 'rails_helper'

RSpec.describe "LINE通知統合テスト", type: :request do
  let(:user) { create(:user) }
  let(:line_notification) { create(:line_notification, user: user) }
  let(:oauth_account) { create(:oauth_account, user: user, provider: 'line_messaging', uid: 'test_line_id') }
  let!(:goal) { create(:goal, user: user) }

  before do
    oauth_account
    line_notification
  end

  describe 'LINE通知のエンドツーエンドテスト' do
    context '3日間投稿していないユーザーへの通知' do
      before do
        # 最後の投稿を4日前に設定
        create(:board, user: user, created_at: 4.days.ago)
      end

      it '通知ジョブが正しく実行される' do
        # ユーザーがLINE通知可能な状態であることを確認
        expect(user.line_notifiable?).to be true
        expect(user.line_id).to eq('test_line_id')
        expect(user.line_notification_setting.can_notify_today?).to be true

        # ユーザーが3日間投稿していないことを確認
        expect(user.boards.where("created_at >= ?", 3.days.ago)).to be_empty

        # CheckInactiveUsersJobのfind_inactive_usersメソッドを直接テスト
        inactive_users = CheckInactiveUsersJob.new.send(:find_inactive_users, 3)
        expect(inactive_users).to include(user)

        # 実際のジョブを実行
        CheckInactiveUsersJob.perform_now

        # CheckInactiveUsersJobはLineInactiveNotifyJobをキューに追加する
        # キューに追加されたことを確認
        expect(LineInactiveNotifyJob).to have_been_enqueued.with(user.id)
      end
    end
  end

  describe 'LINE連携フロー' do
    let(:token) { SecureRandom.urlsafe_base64(24) }
    let!(:link_token) { create(:line_link_token, token: token, messaging_user_id: 'test_line_id') }

    before do
      sign_in user
    end

    it 'LINE連携が正常に完了する' do
      get "/line/link", params: { token: token }

      expect(response).to redirect_to(reminder_settings_path)
      expect(flash[:notice]).to include("すでにLINE通知の連携は完了しています")

      # ユーザーにLINE連携が設定されていることを確認
      expect(user.reload.line_notifiable?).to be true
      expect(user.line_id).to eq('test_line_id')
    end

    it '無効なトークンでエラーになる' do
      get "/line/link", params: { token: 'invalid_token' }

      expect(response).to redirect_to(reminder_settings_path)
      expect(flash[:alert]).to include("連携用リンクが無効または期限切れです")
    end
  end

  describe '通知設定の管理' do
    before do
      sign_in user
    end

    it 'LINE連携解除が正常に動作する' do
      # 連携解除で削除されるべき関連データを作成
      user.line_notification_setting # line_notifications を作成
      user.line_link_tokens.create!(token: 'test-token', messaging_user_id: 'test_line_id', expires_at: 1.hour.from_now)

      delete "/line/notification/disconnect"

      expect(response).to redirect_to(reminder_settings_path)
      expect(flash[:success]).to include("LINE通知連携を解除しました")

      # ユーザーからLINE連携が削除されていることを確認
      user.reload
      expect(user.line_notifiable?).to be false
      expect(user.line_notification).to be_nil
      expect(user.line_link_tokens).to be_empty
    end
  end
end
