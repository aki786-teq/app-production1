require 'rails_helper'

RSpec.describe Board, type: :model do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  it 'is_deleted による last_post_date の影響は無い（User側で参照時に除外）' do
    # 仕様確認用に is_deleted true の投稿を作っても User#last_post_date は未削除のみ最大を返す
    create(:board, user: user, goal: goal, created_at: 2.days.ago, is_deleted: true)
    create(:board, user: user, goal: goal, created_at: 1.day.ago, is_deleted: false)
    expect(user.last_post_date).to eq 1.day.ago.to_date
  end
end


