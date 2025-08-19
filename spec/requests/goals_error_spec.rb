require 'rails_helper'

RSpec.describe "Goals errors", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  it 'create 失敗で422' do
    post goal_path, params: { goal: { goal: '', content: '' } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'update 失敗で422' do
    user.create_goal!(goal: 'x', content: 'y')
    patch goal_path, params: { goal: { goal: '', content: '' } }
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
