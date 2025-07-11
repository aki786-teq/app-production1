class BookmarksController < ApplicationController
  def create
    board = Board.find(params[:board_id])
    bookmark = current_user.bookmarks.new(board_id: board.id)
    bookmark.save

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
