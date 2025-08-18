require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#can_use_stretch_measurement?' do
    let(:user) { create(:user) }
    let!(:goal) { create(:goal, user: user) }

    it '4日連続投稿なら true、そうでなければ false' do
      expect(user.can_use_stretch_measurement?).to be false
      (1..4).each { |i| create(:board, user: user, goal: goal, created_at: i.days.ago) }
      expect(user.reload.can_use_stretch_measurement?).to be true
    end
  end
end


