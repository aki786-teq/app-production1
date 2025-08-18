require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe 'OAuth 連携系' do
    it 'line_connected? / google_connected? / omniauth_user? の分岐' do
      expect(user.line_connected?).to be false
      expect(user.google_connected?).to be false
      expect(user.omniauth_user?).to be false

      user.oauth_accounts.create!(provider: 'line', uid: 'line-uid')
      expect(user.reload.line_connected?).to be true
      expect(user.google_connected?).to be false
      expect(user.omniauth_user?).to be true

      user.oauth_accounts.create!(provider: 'google_oauth2', uid: 'g-uid')
      expect(user.reload.google_connected?).to be true
    end

    it 'connected_to? / oauth_account_for の分岐' do
      expect(user.connected_to?(:line)).to be false
      expect(user.oauth_account_for(:line)).to be_nil

      account = user.oauth_accounts.create!(provider: 'line', uid: 'line-uid')
      expect(user.connected_to?('line')).to be true
      expect(user.oauth_account_for('line')).to eq account
    end

    it 'line_id は line_messaging を優先し、なければ line を返す' do
      expect(user.line_id).to be_nil
      user.oauth_accounts.create!(provider: 'line', uid: 'login-uid')
      expect(user.reload.line_id).to eq 'login-uid'
      user.oauth_accounts.create!(provider: 'line_messaging', uid: 'messaging-uid')
      expect(user.reload.line_id).to eq 'messaging-uid'
    end
  end

  describe '通知可否' do
    it 'line_notifiable? は LINE連携かつ通知ON時のみ true' do
      # デフォルトでは連携なし -> false
      expect(user.line_notifiable?).to be false

      # LINE連携あり & 既定で通知ON -> true
      user.oauth_accounts.create!(provider: 'line', uid: 'line-uid')
      expect(user.reload.line_notification_setting.notification_enabled?).to be true
      expect(user.line_notifiable?).to be true

      # 通知設定OFF -> false
      user.line_notification_setting.update!(notification_enabled: false)
      expect(user.line_notifiable?).to be false
    end
  end

  describe 'パスワード必須判定（オーバーライド）' do
    it 'SNSログインのみ(暗号化パスワードなし)なら password_required? は false' do
      omniauth_user = create(:user)
      omniauth_user.oauth_accounts.create!(provider: 'line', uid: 'line-uid')
      # DB制約に触れないよう、分岐条件のみスタブで再現
      allow(omniauth_user).to receive(:omniauth_user?).and_return(true)
      allow(omniauth_user).to receive(:encrypted_password).and_return(nil)
      expect(omniauth_user.send(:password_required?)).to be false
    end

    it '通常ユーザーは password_required? が true' do
      normal_user = create(:user)
      allow(normal_user).to receive(:omniauth_user?).and_return(false)
      allow(normal_user).to receive(:encrypted_password).and_return('encrypted')
      expect(normal_user.send(:password_required?)).to be true
    end

    it 'SNSログインかつ暗号化パスワードが空文字列の場合は true（present?はfalseだがomniauth_user?もtrueのためfalse→ただし実装はpresent?で真）' do
      u = create(:user)
      allow(u).to receive(:omniauth_user?).and_return(true)
      allow(u).to receive(:encrypted_password).and_return('')
      # 実装は encrypted_password.present? を見るため空文字は false → 全体として !true || false == false
      expect(u.send(:password_required?)).to be false
    end

    it 'SNSログインかつ暗号化パスワードが存在すると true（左辺がfalseのため右辺評価されtrue）' do
      u = create(:user)
      allow(u).to receive(:omniauth_user?).and_return(true)
      allow(u).to receive(:encrypted_password).and_return('encrypted')
      # !true || 'encrypted'.present? => false || true => true
      expect(u.send(:password_required?)).to be true
    end
  end
end


