require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#four_days_consecutive_posts?' do
    let(:user) { create(:user) }
    let!(:goal) { create(:goal, user: user) }

    it '昨日から4日連続で投稿がある場合は true' do
      (1..4).each do |i|
        create(:board, user: user, goal: goal, created_at: i.days.ago)
      end
      expect(user.four_days_consecutive_posts?).to be true
    end
  end

  describe '#consecutive_post_days の分岐' do
    let(:user) { create(:user) }
    let!(:goal) { create(:goal, user: user) }

    it '直近2日連続なら 2 を返す' do
      create(:board, user: user, goal: goal, created_at: 1.day.ago)
      create(:board, user: user, goal: goal, created_at: 2.days.ago)
      expect(user.consecutive_post_days).to eq 2
    end

    it '1日目のみ投稿なら 1 を返す' do
      create(:board, user: user, goal: goal, created_at: 1.day.ago)
      expect(user.consecutive_post_days).to eq 1
    end

    it '途中で欠けていればそこで打ち切る（1日目無し・2日目ありでも 0）' do
      create(:board, user: user, goal: goal, created_at: 2.days.ago)
      expect(user.consecutive_post_days).to eq 0
    end
  end
end


