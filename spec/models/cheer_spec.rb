require 'rails_helper'

RSpec.describe Cheer, type: :model do
  let(:user) { create(:user) }
  let(:goal) { create(:goal, user: user) }
  let(:board_author) { create(:user) }
  let(:author_goal) { create(:goal, user: board_author) }
  let(:board) { create(:board, user: board_author, goal: author_goal) }

  it '作成時に通知を作る' do
    expect { described_class.create!(user: user, board: board) }
      .to change { Notification.count }.by(1)
  end

  it '同一 user-board の重複を許さない' do
    described_class.create!(user: user, board: board)
    dup = described_class.new(user: user, board: board)
    expect(dup).to be_invalid
  end
end
