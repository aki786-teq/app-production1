require 'rails_helper'

RSpec.describe Notification, type: :model do
  it 'enum action_type の定義がある' do
    expect(described_class.action_types.keys).to include('cheer')
  end

  it 'アソシエーションが有効' do
    user = create(:user)
    goal = create(:goal, user: user)
    board = create(:board, user: user, goal: goal)
    cheer = board.cheers.create!(user: user)
    n = described_class.create!(user: user, subject: cheer, action_type: :cheer)
    expect(n.user).to eq user
    expect(n.subject).to eq cheer
  end
end


