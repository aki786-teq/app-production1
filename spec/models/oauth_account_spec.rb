require 'rails_helper'

RSpec.describe OauthAccount, type: :model do
  it 'provider/uid のpresence' do
    oa = described_class.new
    expect(oa).to be_invalid
    expect(oa.errors[:provider]).to be_present
    expect(oa.errors[:uid]).to be_present
  end

  it 'provider+uid の一意性' do
    user = create(:user)
    described_class.create!(user: user, provider: 'google_oauth2', uid: 'u1')
    dup = described_class.new(user: user, provider: 'google_oauth2', uid: 'u1')
    expect(dup).to be_invalid
  end
end


