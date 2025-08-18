require 'rails_helper'

RSpec.describe "Devise sessions guard", type: :request do
  let(:user) { create(:user) }

  it '目標未設定でも sign_out は new_goal にリダイレクトさせない' do
    sign_in user
    delete destroy_user_session_path
    # Devise標準の遷移（rootやサインイン画面など）であればOK。少なくとも new_goal ではないことを確認
    expect(response).to have_http_status(302).or have_http_status(303)
    expect(response.headers['Location']).not_to include(new_goal_path)
  end
end


