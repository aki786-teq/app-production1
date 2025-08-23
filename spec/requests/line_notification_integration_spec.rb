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
        # 実際のジョブを実行
        perform_enqueued_jobs do
          CheckInactiveUsersJob.perform_now
        end

        # CheckInactiveUsersJobはLineInactiveNotifyJobを実行するため、consecutive_inactive_daysが増加する
        expect(line_notification.reload.consecutive_inactive_days).to eq(1)
      end
    end

    context '投稿後の通知リセット' do
      before do
        # 通知済み状態を作成
        line_notification.update!(consecutive_inactive_days: 3, last_notified_at: 1.day.ago)
      end

      it '新しい投稿で通知カウントがリセットされる' do
        sign_in user

        # コントローラーを経由して投稿を作成（reset_inactive_days!が呼ばれる）
        post boards_path, params: { board: { did_stretch: true, goal_id: goal.id } }

        # 通知カウントがリセットされることを確認
        expect(line_notification.reload.consecutive_inactive_days).to eq(0)
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
      expect(user.reload.line_connected?).to be true
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
      delete "/line/notification/disconnect"

      expect(response).to redirect_to(reminder_settings_path)
      expect(flash[:success]).to include("LINE通知連携を解除しました")

      # ユーザーからLINE連携が削除されていることを確認
      expect(user.reload.line_connected?).to be false
    end
  end
end
