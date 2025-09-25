require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'can_use_stretch_measurement?' do
    let(:user) { create(:user) }

    it '投稿がないと false' do
      expect(user.can_use_stretch_measurement?).to be false
    end
  end

  describe '#consecutive_post_days' do
    let(:user) { create(:user) }

    it '投稿がないと 0' do
      expect(user.consecutive_post_days).to eq 0
    end
  end
end
