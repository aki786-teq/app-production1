require 'rails_helper'

RSpec.describe LineLinkToken, type: :model do
  let(:user) { create(:user) }

  describe 'バリデーション' do
    it 'token/messaging_user_id のpresenceとtoken一意性' do
      t = described_class.new
      expect(t).to be_invalid
      expect(t.errors[:token]).to be_present
      expect(t.errors[:messaging_user_id]).to be_present

      create(:line_link_token, token: 'dup-token')
      dup = build(:line_link_token, token: 'dup-token')
      expect(dup).to be_invalid
    end
  end

  describe '.valid_unconsumed' do
    it '有効期限内かつ未使用のみ含む（C1分岐）' do
      valid_token = create(:line_link_token, expires_at: 10.minutes.from_now, consumed_at: nil)
      expired = create(:line_link_token, expires_at: 1.minute.ago, consumed_at: nil)
      consumed = create(:line_link_token, expires_at: 10.minutes.from_now, consumed_at: Time.current)

      result = described_class.valid_unconsumed
      expect(result).to include(valid_token)
      expect(result).not_to include(expired)
      expect(result).not_to include(consumed)
    end
  end

  describe '#consumed?' do
    it 'consumed_at があれば true、なければ false' do
      token = build(:line_link_token, consumed_at: nil)
      expect(token.consumed?).to be false
      token.consumed_at = Time.current
      expect(token.consumed?).to be true
    end
  end

  describe '#consume!' do
    it 'consumed_at と user_id を設定して永続化する' do
      token = create(:line_link_token, consumed_at: nil)
      expect {
        token.consume!(user: user)
      }.to change { token.reload.consumed_at.present? }.from(false).to(true)
      expect(token.user_id).to eq user.id
    end
  end
end


