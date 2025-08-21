require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#line_notification_setting' do
    it '既存が無ければ作成して返す' do
      user = create(:user)
      setting = user.line_notification_setting
      expect(setting).to be_persisted
      expect(setting.user_id).to eq user.id
    end
  end
end
