require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe 'OAuth 連携系' do
    it 'line_notifiable? はLINE連携時に true になる' do
      expect(user.line_notifiable?).to be false

      user.oauth_accounts.create!(provider: 'line_messaging', uid: 'line-uid')
      expect(user.reload.line_notifiable?).to be true
    end

    it 'line_id は line_messaging のUIDを返す' do
      expect(user.line_id).to be_nil
      user.oauth_accounts.create!(provider: 'line_messaging', uid: 'messaging-uid')
      expect(user.reload.line_id).to eq 'messaging-uid'
    end
  end

  describe '通知可否' do
    it 'line_notifiable? は LINE連携時のみ true' do
      # デフォルトでは連携なし -> false
      expect(user.line_notifiable?).to be false

      # LINE連携あり -> true
      user.oauth_accounts.create!(provider: 'line_messaging', uid: 'line-uid')
      expect(user.reload.line_notifiable?).to be true
    end
  end
end
