require 'rails_helper'

RSpec.describe Goal, type: :model do
  it 'goal/content のpresence' do
    g = described_class.new
    expect(g).to be_invalid
    expect(g.errors[:goal]).to be_present
    expect(g.errors[:content]).to be_present
  end
end


