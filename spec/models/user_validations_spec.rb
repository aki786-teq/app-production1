require 'rails_helper'

RSpec.describe User, type: :model do
  it 'name の presence' do
    u = described_class.new(email: 'x@example.com', password: 'password123', name: nil)
    expect(u).to be_invalid
    expect(u.errors[:name]).to be_present
  end

  it 'introduce は 500 文字以内' do
    u = build(:user, introduce: 'a' * 501)
    expect(u).to be_invalid
    u.introduce = 'a' * 500
    expect(u).to be_valid
  end

  it 'email の uniqueness' do
    create(:user, email: 'dup@example.com')
    dup = build(:user, email: 'dup@example.com')
    expect(dup).to be_invalid
  end

  it 'email_required? は true を返す' do
    expect(build(:user).send(:email_required?)).to be true
  end
end


