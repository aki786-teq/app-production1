require 'rails_helper'

RSpec.describe "Goals", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  it 'GET /goal/new は 200' do
    get new_goal_path
    expect(response).to have_http_status(:ok)
  end

  it 'POST /goal で作成できる' do
    post goal_path, params: { goal: { goal: '床に指', content: '毎日3分' } }
    expect(response).to redirect_to(edit_goal_path)
  end

  it 'GET /goal/edit は 200' do
    user.create_goal!(goal: '床に指', content: '毎日3分')
    get edit_goal_path
    expect(response).to have_http_status(:ok)
  end
end


