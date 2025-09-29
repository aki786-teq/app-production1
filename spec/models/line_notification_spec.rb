require 'rails_helper'

RSpec.describe LineNotification, type: :model do
  let(:user) { create(:user) }
  let!(:setting) { described_class.create!(user: user) }

  describe 'バリデーション' do
    it 'user_id の presence/uniqueness' do
      invalid = described_class.new
      expect(invalid).to be_invalid
      expect(invalid.errors[:user]).to be_present

      # 既にsettingでuserに紐づくレコードが作成されているため、重複して作成しようとすると失敗するはず
      duplicate_setting = described_class.new(user: user)
      expect(duplicate_setting).to be_invalid
    end
  end

  it 'can_notify_today? は初期状態で true' do
    expect(setting.can_notify_today?).to be true
  end

  it '同日重複は can_notify_today? が false' do
    setting.update!(last_notified_at: Time.current)
    expect(setting.can_notify_today?).to be false
  end

  it 'record_notification! で last_notified_at が更新される' do
    expect { setting.record_notification! }.to change { setting.reload.last_notified_at }.from(nil)
  end
end
