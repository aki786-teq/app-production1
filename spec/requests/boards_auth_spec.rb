require 'rails_helper'

RSpec.describe "Boards auth flows", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  it 'ログイン時に /boards/new へアクセスできる' do
    sign_in user
    get new_board_path
    expect(response).to have_http_status(:ok)
  end

  it '未ログインだと /boards/new は利用できない' do
    get new_board_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'POST /boards で作成できる' do
    sign_in user
    post boards_path, params: { board: { did_stretch: true, content: 'rspec', flexibility_level: 1 } }
    expect(response).to have_http_status(:found).or have_http_status(:see_other)
    expect(response).to redirect_to(boards_path)
  end
end
