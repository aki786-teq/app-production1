require 'rails_helper'

RSpec.describe Board, type: :model do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  it 'item_price は 0 より大きい数値のみ許可' do
    b = build(:board, user: user, goal: goal, item_price: 0)
    expect(b).to be_invalid
    b.item_price = 100
    expect(b).to be_valid
  end

  it 'item_url は http/https のみ許可' do
    b = build(:board, user: user, goal: goal, item_url: 'ftp://example.com')
    expect(b).to be_invalid
    b.item_url = 'https://example.com'
    expect(b).to be_valid
  end

  it 'item_image_url も http/https のみ許可' do
    b = build(:board, user: user, goal: goal, item_image_url: 'javascript:alert(1)')
    expect(b).to be_invalid
    b.item_image_url = 'http://example.com/image.jpg'
    expect(b).to be_valid
  end

  it 'content は1000文字以内' do
    b = build(:board, user: user, goal: goal, content: 'a' * 1001)
    expect(b).to be_invalid
    b.content = 'a' * 1000
    expect(b).to be_valid
  end
end
