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
end
