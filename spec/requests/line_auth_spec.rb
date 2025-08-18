require 'rails_helper'

RSpec.describe "LineAuth", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before { sign_in user }

  it 'DELETE /auth/line/disconnect 連携あり → 成功リダイレクト' do
    user.oauth_accounts.create!(provider: 'line', uid: 'line_login_uid')
    user.oauth_accounts.create!(provider: 'line_messaging', uid: 'line_msg_uid')
    delete line_auth_disconnect_path
    expect([302, 303]).to include(response.status)
    expect(response).to redirect_to(reminder_settings_path)
  end

  it 'DELETE /auth/line/disconnect 連携なし → リダイレクト（フラッシュは存在）' do
    delete line_auth_disconnect_path
    expect([302, 303]).to include(response.status)
    expect(response).to redirect_to(reminder_settings_path)
  end
end


