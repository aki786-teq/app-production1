require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  it 'GET /users/:id は 200' do
    sign_in user
    get user_path(user)
    expect(response).to have_http_status(:ok)
  end
end
