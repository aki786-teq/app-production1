require 'rails_helper'

RSpec.describe CheckInactiveUsersJob, type: :job do
  let(:user) { create(:user) }
  let(:line_notification) { create(:line_notification, user: user) }
  let(:oauth_account) { create(:oauth_account, user: user, provider: 'line_messaging', uid: 'test_line_id') }

  before do
    oauth_account
    line_notification
  end

  describe '#perform' do
    context '3日間投稿していないユーザーがいる場合' do
      before do
        # 最後の投稿を4日前に設定
        create(:board, user: user, created_at: 4.days.ago)
      end

      it 'LineInactiveNotifyJobをキューに追加する' do
        expect(LineInactiveNotifyJob).to receive(:perform_later).with(user.id)
        
        perform_enqueued_jobs { described_class.perform_now }
      end

      it '通知可能なユーザーにのみジョブを追加する' do
        # LINE連携を削除して通知不可にする
        oauth_account.destroy
        
        expect(LineInactiveNotifyJob).not_to receive(:perform_later)
        
        perform_enqueued_jobs { described_class.perform_now }
      end
    end

    context '同日に既に通知済みの場合' do
      before do
        create(:board, user: user, created_at: 4.days.ago)
        line_notification.update!(last_notified_at: Time.current)
      end

      it '重複通知を防ぐ' do
        expect(LineInactiveNotifyJob).not_to receive(:perform_later)
        
        perform_enqueued_jobs { described_class.perform_now }
      end
    end

    context '3日以内に投稿がある場合' do
      before do
        create(:board, user: user, created_at: 2.days.ago)
      end

      it '通知ジョブを追加しない' do
        expect(LineInactiveNotifyJob).not_to receive(:perform_later)
        
        perform_enqueued_jobs { described_class.perform_now }
      end
    end

    context 'LINE連携されていないユーザーの場合' do
      before do
        oauth_account.destroy
        create(:board, user: user, created_at: 4.days.ago)
      end

      it '通知ジョブを追加しない' do
        expect(LineInactiveNotifyJob).not_to receive(:perform_later)
        
        perform_enqueued_jobs { described_class.perform_now }
      end
    end

    context '削除済みユーザーの場合' do
      before do
        user.update!(is_deleted: true)
        create(:board, user: user, created_at: 4.days.ago)
      end

      it '通知ジョブを追加しない' do
        expect(LineInactiveNotifyJob).not_to receive(:perform_later)
        
        perform_enqueued_jobs { described_class.perform_now }
      end
    end

    context '複数ユーザーがいる場合' do
      let(:user2) { create(:user) }
      let(:line_notification2) { create(:line_notification, user: user2) }
      let(:oauth_account2) { create(:oauth_account, user: user2, provider: 'line_messaging', uid: 'test_line_id2') }

      before do
        oauth_account2
        line_notification2
        create(:board, user: user, created_at: 4.days.ago)
        create(:board, user: user2, created_at: 4.days.ago)
      end

      it '両方のユーザーに通知ジョブを追加する' do
        expect(LineInactiveNotifyJob).to receive(:perform_later).with(user.id)
        expect(LineInactiveNotifyJob).to receive(:perform_later).with(user2.id)
        
        perform_enqueued_jobs { described_class.perform_now }
      end
    end
  end

  describe 'エラーハンドリング' do
    before do
      create(:board, user: user, created_at: 4.days.ago)
    end

    it '個別ユーザーのエラーが全体の処理を停止させない' do
      # LineInactiveNotifyJobでエラーを発生させる
      allow(LineInactiveNotifyJob).to receive(:perform_later).and_raise(StandardError.new("テストエラー"))
      
      expect(Rails.logger).to receive(:error).with(/テストエラー/)
      
      # エラーが発生しても処理が継続されることを確認
      perform_enqueued_jobs { described_class.perform_now }
    end
  end
end
