require 'rails_helper'

RSpec.describe "Users edges", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before { sign_in user }

  it 'プロフィール更新失敗で422' do
    patch update_profile_user_path(user), params: { user: { name: '' } }
    expect(response).to have_http_status(:unprocessable_entity)
  end
end


