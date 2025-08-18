require 'rails_helper'

RSpec.describe "Goals guard", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  it '目標未設定だと /users/:id でも new_goal にリダイレクト' do
    get user_path(user)
    expect([302, 303]).to include(response.status)
    expect(response).to redirect_to(new_goal_path)
  end
end


