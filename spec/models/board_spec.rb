require 'rails_helper'

RSpec.describe Board, type: :model do
  it '有効なファクトリを持つ' do
    expect(build(:board)).to be_valid
  end

  it 'did_stretch は必須' do
    board = build(:board, did_stretch: nil)
    expect(board).to be_invalid
    expect(board.errors[:did_stretch]).to be_present
  end

  it 'flexibility_level は整数であること' do
    board = build(:board, flexibility_level: 1.5)
    expect(board).to be_invalid
  end
end



