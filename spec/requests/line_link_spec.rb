require 'rails_helper'

RSpec.describe "Line link", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before { sign_in user }

  it 'GET /line/link?token=... 有効トークンで連携成功しリダイレクト' do
    token = LineLinkToken.create!(token: SecureRandom.hex(8), messaging_user_id: 'Uxxxx', expires_at: 30.minutes.from_now)
    get "/line/link", params: { token: token.token }
    expect([302, 303]).to include(response.status)
    expect(response).to redirect_to(reminder_settings_path)
    expect(user.reload.oauth_accounts.find_by(provider: 'line_messaging')).to be_present
  end

  it 'GET /line/link 不正/期限切れトークンはリダイレクト' do
    get "/line/link", params: { token: 'invalid' }
    expect([302, 303]).to include(response.status)
    expect(response).to redirect_to(reminder_settings_path)
  end

  it 'GET /line/link 既に連携済みなら再消費してリダイレクト' do
    token = LineLinkToken.create!(token: SecureRandom.hex(8), messaging_user_id: 'Uyyyy', expires_at: 30.minutes.from_now)
    user.oauth_accounts.create!(provider: 'line_messaging', uid: 'Uyyyy')
    get "/line/link", params: { token: token.token }
    expect([302, 303]).to include(response.status)
    expect(response).to redirect_to(reminder_settings_path)
    expect(token.reload.consumed?).to eq(true)
  end
end


