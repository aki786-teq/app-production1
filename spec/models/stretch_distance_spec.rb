require 'rails_helper'

RSpec.describe StretchDistance, type: :model do
  let(:user) { create(:user) }

  it 'flexibility_level が必須' do
    sd = described_class.new(user: user)
    expect(sd).to be_invalid
    expect(sd.errors[:flexibility_level]).to be_present
  end

  it 'flexibility_level を設定すると comment_template が自動設定される' do
    sd = described_class.create!(user: user, flexibility_level: 'good')
    expect(sd.comment_template).to be_present
  end

  it 'localized_flexibility_level の分岐' do
    sd = described_class.new(user: user, flexibility_level: 'good')
    expect(sd.localized_flexibility_level).to eq '良好'
    sd.flexibility_level = 'unknown'
    expect(sd.localized_flexibility_level).to eq 'unknown'
  end

  it 'generate_comment は未知レベルで nil を返す（フォールバック）' do
    sd = described_class.new(user: user, flexibility_level: 'xxx')
    sd.send(:set_flexibility_data)
    expect(sd.comment_template).to be_nil
  end
end


