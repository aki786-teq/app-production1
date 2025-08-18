require 'rails_helper'

RSpec.describe "StretchDistances errors", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before do
    # 連続投稿達成状態にする
    (1..4).each do |i|
      create(:board, user: user, goal: goal, created_at: i.days.ago)
    end
    sign_in user
  end

  it 'create_post_with_result は存在しないIDで measure にリダイレクト' do
    post create_post_with_result_stretch_distance_path(999999)
    expect([302, 303]).to include(response.status)
    expect(response).to redirect_to(measure_stretch_distances_path)
  end
end


