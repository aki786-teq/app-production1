require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#last_post_date / #inactive_for_days?' do
    let(:user) { create(:user) }
    let!(:goal) { create(:goal, user: user) }

    it '投稿が無い場合は last_post_date が nil、inactive_for_days? は true' do
      expect(user.last_post_date).to be_nil
      expect(user.inactive_for_days?(3)).to be true
    end

    it '直近の投稿日に基づいて inactive_for_days? を判定' do
      create(:board, user: user, goal: goal, created_at: 5.days.ago)
      expect(user.inactive_for_days?(3)).to be true
      create(:board, user: user, goal: goal, created_at: 1.day.ago)
      expect(user.reload.inactive_for_days?(3)).to be false
    end
  end

  describe '#line_notification_setting' do
    it '既存が無ければ作成して返す' do
      user = create(:user)
      setting = user.line_notification_setting
      expect(setting).to be_persisted
      expect(setting.user_id).to eq user.id
    end
  end
end


