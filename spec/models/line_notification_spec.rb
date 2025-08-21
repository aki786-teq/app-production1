require 'rails_helper'

RSpec.describe LineNotification, type: :model do
  let(:user) { create(:user) }
  let(:setting) { described_class.create!(user: user, consecutive_inactive_days: 0) }

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
