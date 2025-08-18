require 'rails_helper'

RSpec.describe Bookmark, type: :model do
  it '同一 user-board の重複を許さない' do
    user = create(:user)
    goal = create(:goal, user: user)
    board = create(:board, user: user, goal: goal)
    described_class.create!(user: user, board: board)
    dup = described_class.new(user: user, board: board)
    expect(dup).to be_invalid
  end
end


