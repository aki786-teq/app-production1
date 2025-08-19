require 'rails_helper'

RSpec.describe "Boards edges", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before { sign_in user }

  it 'GET /boards/:id は 200 を返す' do
    board = create(:board, user: user, goal: goal)
    get board_path(board)
    expect(response).to have_http_status(:ok)
  end

  it '他人の編集URLは404を返す' do
    other = create(:user)
    other_goal = create(:goal, user: other)
    board = create(:board, user: other, goal: other_goal)
    get edit_board_path(board)
    expect(response).to have_http_status(:not_found).or have_http_status(404)
  end

  it '更新失敗（不正YouTubeリンク）で422' do
    board = create(:board, user: user, goal: goal)
    patch board_path(board), params: { board: { youtube_link: 'invalid', did_stretch: true } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it '同日に既に投稿があると new はリダイレクト' do
    create(:board, user: user, goal: goal, created_at: Time.zone.now)
    get new_board_path
    expect([ 302, 303 ]).to include(response.status)
    expect(response).to redirect_to(boards_path)
  end

  it '同日に既に投稿があると create はリダイレクト' do
    create(:board, user: user, goal: goal, created_at: Time.zone.now)
    post boards_path, params: { board: { did_stretch: true, content: 'x' } }
    expect([ 302, 303 ]).to include(response.status)
    expect(response).to redirect_to(boards_path)
  end
end
