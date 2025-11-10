class BookmarksController < ApplicationController
  def create
    board = Board.find(params[:board_id])
    bookmark = current_user.bookmarks.new(board_id: board.id)
    bookmark.save

    bookmarks = current_user.bookmarks
    @bookmarks_map = bookmarks.index_by(&:board_id)
    @bookmarked_board_ids = @bookmarks_map.keys.to_set

    respond_to do |format|
      format.html { redirect_to request.referer }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "bookmark-button-#{board.id}",
          partial: "bookmarks/btn",
          locals: { board: board }
        )
      end
    end
  end

  def destroy
    board = Board.find(params[:board_id])
    bookmark = current_user.bookmarks.find_by(board_id: board.id)
    bookmark.destroy

    bookmarks = current_user.bookmarks
    @bookmarks_map = bookmarks.index_by(&:board_id)
    @bookmarked_board_ids = @bookmarks_map.keys.to_set

    respond_to do |format|
      format.html { redirect_to request.referer }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "bookmark-button-#{board.id}",
          partial: "bookmarks/btn",
          locals: { board: board }
        )
      end
    end
  end
end
