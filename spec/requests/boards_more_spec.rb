require 'rails_helper'

RSpec.describe "Boards more flows", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before { sign_in user }

  it '新規作成失敗時は422でnewを再表示' do
    post boards_path, params: { board: { did_stretch: nil, content: 'ng' } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it '編集/更新/削除フローが動作する' do
    board = create(:board, user: user, goal: goal)

    get edit_board_path(board)
    expect(response).to have_http_status(:ok)

    patch board_path(board), params: { board: { content: 'updated', did_stretch: true } }
    expect([ 302, 303 ]).to include(response.status)
    expect(response).to redirect_to(boards_path)

    delete board_path(board)
    expect([ 302, 303 ]).to include(response.status)
    expect(response).to redirect_to(boards_path)
  end

  it 'bookmarks一覧は200' do
    get bookmarks_boards_path
    expect(response).to have_http_status(:ok)
  end

  it 'search_items keywordなしは空配列JSON' do
    get search_items_boards_path
    json = JSON.parse(response.body)
    expect(json['items']).to eq([])
  end

  it 'search_items 例外時は422を返す' do
    allow(RakutenWebService::Ichiba::Item).to receive(:search).and_raise(StandardError.new('api error'))
    get search_items_boards_path, params: { keyword: 'yoga' }
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
