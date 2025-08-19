require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#four_days_consecutive_posts?' do
    let(:user) { create(:user) }

    it '投稿がないと false' do
      expect(user.four_days_consecutive_posts?).to be false
    end
  end

  describe '#consecutive_post_days' do
    let(:user) { create(:user) }

    it '投稿がないと 0' do
      expect(user.consecutive_post_days).to eq 0
    end
  end
end
