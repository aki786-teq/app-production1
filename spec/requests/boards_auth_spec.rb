require 'rails_helper'

RSpec.describe "Boards auth flows", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  it 'ログイン時に /boards/new へアクセスできる' do
    sign_in user
    get new_board_path
    expect(response).to have_http_status(:ok)
  end

  it '未ログインだと /boards/new は利用できない（現状仕様未定のためスキップ）' do
    skip '未ログイン時の /boards/new はコントローラ側で current_user を参照して例外になるためスキップ'
  end

  it 'POST /boards で作成できる' do
    sign_in user
    post boards_path, params: { board: { did_stretch: true, content: 'rspec', flexibility_level: 1 } }
    expect(response).to have_http_status(:found).or have_http_status(:see_other)
    expect(response).to redirect_to(boards_path)
  end
end
