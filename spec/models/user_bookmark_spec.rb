require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#bookmark / #unbookmark / #bookmark?' do
    let(:user) { create(:user) }
    let(:author) { create(:user) }
    let!(:goal) { create(:goal, user: author) }
    let!(:board) { create(:board, user: author, goal: goal) }

    it 'ブックマーク操作の往復ができる' do
      expect(user.bookmark?(board)).to be false
      user.bookmark(board)
      expect(user.bookmark?(board)).to be true
      user.unbookmark(board)
      expect(user.bookmark?(board)).to be false
    end
  end
end


