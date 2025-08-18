require 'rails_helper'

RSpec.describe "Notifications edge", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before { sign_in user }

  it 'index で未読が既読化される' do
    board = create(:board, user: user, goal: goal)
    other = create(:user)
    create(:goal, user: other)
    # 他人からのCheerで通知が作成される
    other.cheers.create!(board: board)
    get notifications_path
    expect(response).to have_http_status(:ok)
    expect(user.notifications.reload.where(checked: false).count).to eq(0)
  end
end


