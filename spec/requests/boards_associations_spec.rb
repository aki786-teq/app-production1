require 'rails_helper'

RSpec.describe "Boards associations", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before { sign_in user }

  it 'POST /boards で stretch_distance_id を関連付ける' do
    sd = create(:stretch_distance, user: user)
    post boards_path, params: { board: { did_stretch: true, content: 'with sd' }, stretch_distance_id: sd.id }
    expect([ 302, 303 ]).to include(response.status)
    board = Board.order(:created_at).last
    expect(board.stretch_distances).to include(sd)
  end

  it '投稿成功時に line_notification_setting.reset_inactive_days! が呼ばれ 0 にリセットされる' do
    ln = user.line_notification_setting
    ln.update!(consecutive_inactive_days: 3)

    post boards_path, params: { board: { did_stretch: true, content: 'reset inactive' } }
    expect([ 302, 303 ]).to include(response.status)
    expect(user.reload.line_notification_setting.consecutive_inactive_days).to eq(0)
  end
end
