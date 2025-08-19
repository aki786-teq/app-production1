require 'rails_helper'
require 'ostruct'

RSpec.describe User, type: :model do
  describe '.extract_name_from_auth' do
    it 'provider=line の場合は info.name/display_name を優先' do
      auth = OpenStruct.new(provider: 'line', info: OpenStruct.new(name: nil, display_name: 'Disp'))
      expect(described_class.extract_name_from_auth(auth)).to eq 'Disp'
    end

    it 'provider=google_oauth2 の場合は info.name を優先' do
      auth = OpenStruct.new(provider: 'google_oauth2', info: OpenStruct.new(name: 'GUser'))
      expect(described_class.extract_name_from_auth(auth)).to eq 'GUser'
    end

    it 'その他は info.name がなければ "User"' do
      auth = OpenStruct.new(provider: 'github', info: OpenStruct.new(name: nil))
      expect(described_class.extract_name_from_auth(auth)).to eq 'User'
    end
  end

  describe '.find_user_by_google' do
    it 'OauthAccount があればそのユーザーを返す' do
      user = create(:user)
      account = user.oauth_accounts.create!(provider: 'google_oauth2', uid: 'gid1')
      auth = OpenStruct.new(provider: 'google_oauth2', uid: 'gid1', info: OpenStruct.new(email: nil))
      expect(described_class.find_user_by_google(auth)).to eq user
    end

    it 'アカウントが無くても email が一致すればそのユーザーを返す' do
      user = create(:user, email: 'match@example.com')
      auth = OpenStruct.new(provider: 'google_oauth2', uid: 'gid2', info: OpenStruct.new(email: 'match@example.com'))
      expect(described_class.find_user_by_google(auth)).to eq user
    end

    it 'respond_to?(:info) && info.email.present? が true の経路を明示（email一致で find_by が呼ばれる）' do
      user = create(:user, email: 'route@example.com')
      auth = OpenStruct.new(provider: 'google_oauth2', uid: 'gid-route', info: OpenStruct.new(email: 'route@example.com'))
      # 条件がtrueになることを確認
      expect(auth.respond_to?(:info) && auth.info&.email.present?).to be true
      expect(described_class.find_user_by_google(auth)).to eq user
    end

    it '見つからない場合は nil' do
      auth = OpenStruct.new(provider: 'google_oauth2', uid: 'gid3', info: OpenStruct.new(email: 'none@example.com'))
      expect(described_class.find_user_by_google(auth)).to be_nil
    end

    it 'auth が info を持たない場合でも安全に nil を返す（respond_to?(:info) == false 経路）' do
      auth = OpenStruct.new(provider: 'google_oauth2', uid: 'gid4')
      expect(auth.respond_to?(:info)).to be false
      expect(described_class.find_user_by_google(auth)).to be_nil
    end

    it 'info はあるが email が空文字の場合は nil（present? が false）' do
      auth = OpenStruct.new(provider: 'google_oauth2', uid: 'gid5', info: OpenStruct.new(email: ''))
      expect(described_class.find_user_by_google(auth)).to be_nil
    end

    it 'info はあるが email が nil の場合は nil（present? が false）' do
      auth = OpenStruct.new(provider: 'google_oauth2', uid: 'gid6', info: OpenStruct.new(email: nil))
      expect(described_class.find_user_by_google(auth)).to be_nil
    end
  end

  describe '.create_user_for_google!' do
    it 'ユーザーを作成し確認済みにする' do
      auth = OpenStruct.new(provider: 'google_oauth2', info: OpenStruct.new(email: 'new@example.com', name: 'New'))
      user = described_class.create_user_for_google!(auth)
      expect(user).to be_persisted
      expect(user.email).to eq 'new@example.com'
      expect(user).to be_confirmed
    end
  end

  describe '.attach_google_oauth!' do
    it '既に紐付いている場合は重複作成しない' do
      user = create(:user)
      user.oauth_accounts.create!(provider: 'google_oauth2', uid: 'gid1')
      auth = OpenStruct.new(provider: 'google_oauth2', uid: 'gid1')
      expect { described_class.attach_google_oauth!(user, auth) }.not_to change { user.oauth_accounts.count }
    end

    it '未紐付けなら作成する' do
      user = create(:user)
      auth = OpenStruct.new(provider: 'google_oauth2', uid: 'gid2', to_hash: { any: 'x' })
      expect { described_class.attach_google_oauth!(user, auth) }.to change { user.oauth_accounts.count }.by(1)
    end
  end

  describe '.from_omniauth' do
    it '既存アカウントでユーザーを返し、重複作成しない' do
      user = create(:user, email: 'exist@example.com')
      user.oauth_accounts.create!(provider: 'google_oauth2', uid: 'gid1')
      auth = OpenStruct.new(provider: 'google_oauth2', uid: 'gid1', info: OpenStruct.new(email: 'exist@example.com', name: 'N'))
      expect { described_class.from_omniauth(auth) }.not_to change { User.count }
    end

    it 'メール一致でOAuthを紐付ける' do
      user = create(:user, email: 'exist2@example.com')
      auth = OpenStruct.new(provider: 'google_oauth2', uid: 'gid2', info: OpenStruct.new(email: 'exist2@example.com', name: 'N'))
      result = described_class.from_omniauth(auth)
      expect(result).to eq user
      expect(user.oauth_accounts.find_by(provider: 'google_oauth2', uid: 'gid2')).to be_present
    end

    it '新規作成して紐付ける' do
      auth = OpenStruct.new(provider: 'google_oauth2', uid: 'gid3', info: OpenStruct.new(email: 'new2@example.com', name: 'N'))
      expect { described_class.from_omniauth(auth) }.to change { User.count }.by(1)
    end
  end
end
