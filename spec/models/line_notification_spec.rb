require 'rails_helper'

RSpec.describe LineNotification, type: :model do
  let(:user) { create(:user) }
  let(:setting) { described_class.create!(user: user, consecutive_inactive_days: 0) }

  describe 'バリデーション' do
    it 'user_id の presence/uniqueness' do
      invalid = described_class.new
      expect(invalid).to be_invalid
      expect(invalid.errors[:user]).to be_present

      described_class.create!(user: user, consecutive_inactive_days: 0)
      dup = described_class.new(user: user, consecutive_inactive_days: 0)
      expect(dup).to be_invalid
    end

    it 'consecutive_inactive_days は 0 以上の数値' do
      invalid = described_class.new(user: user, consecutive_inactive_days: -1)
      expect(invalid).to be_invalid
      expect(invalid.errors[:consecutive_inactive_days]).to be_present
    end
  end

  it '新規作成時 consecutive_inactive_days は 0 に初期化される' do
    fresh = described_class.create!(user: create(:user))
    expect(fresh.consecutive_inactive_days).to eq 0
  end

  it 'can_notify_today? は初期状態で true' do
    expect(setting.can_notify_today?).to be true
  end

  it '同日重複は can_notify_today? が false' do
    setting.update!(last_notified_at: Time.current)
    expect(setting.can_notify_today?).to be false
  end

  it 'record_notification! で連続無投稿日数が増える' do
    expect { setting.record_notification! }.to change { setting.reload.consecutive_inactive_days }.by(1)
  end

  it 'reset_inactive_days! で 0 になる' do
    setting.update!(consecutive_inactive_days: 3)
    setting.reset_inactive_days!
    expect(setting.reload.consecutive_inactive_days).to eq 0
  end
end
