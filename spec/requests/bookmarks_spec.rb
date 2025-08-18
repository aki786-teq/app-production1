require 'rails_helper'

RSpec.describe "Bookmarks", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }
  let(:author) { create(:user) }
  let!(:author_goal) { create(:goal, user: author) }
  let!(:board) { create(:board, user: author, goal: author_goal) }

  before { sign_in user }

  it 'POST /boards/:board_id/bookmarks は リダイレクトする' do
    post board_bookmarks_path(board), headers: { 'HTTP_REFERER' => boards_path }
    expect([302, 303]).to include(response.status)
  end

  it 'DELETE /boards/:board_id/bookmarks/:id は リダイレクトする' do
    bookmark = user.bookmarks.create!(board: board)
    delete board_bookmark_path(board, bookmark), headers: { 'HTTP_REFERER' => boards_path }
    expect([302, 303]).to include(response.status)
  end
end


