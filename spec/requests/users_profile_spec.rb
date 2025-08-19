require 'rails_helper'

RSpec.describe "Users profiles", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before { sign_in user }

  it 'GET /users/:id.turbo_stream で200' do
    get user_path(user, format: :turbo_stream)
    expect(response).to have_http_status(:ok)
  end

  it 'GET /users/:id/edit_profile で200' do
    get edit_profile_user_path(user)
    expect(response).to have_http_status(:ok)
  end

  it 'PATCH /users/:id/update_profile 成功でリダイレクト' do
    patch update_profile_user_path(user), params: { user: { name: 'new name' } }
    expect([ 302, 303 ]).to include(response.status)
    expect(response).to redirect_to(user_path(user))
  end

  it 'PATCH /users/:id/update_profile 他人のIDだとリダイレクト' do
    other = create(:user)
    other_goal = create(:goal, user: other)
    patch update_profile_user_path(other), params: { user: { name: 'bad' } }
    expect([ 302, 303 ]).to include(response.status)
    expect(response).to redirect_to(root_path)
  end
end
