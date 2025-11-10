class HomeController < ApplicationController
  def index
    start_time = 7.days.ago.beginning_of_day
    end_time = 1.day.ago.end_of_day

    @ranking_boards = Board
      .with_attached_image
      .left_joins(:cheers, :bookmarks)
      .where(created_at: start_time..end_time)
      .group("boards.id")
      .select("boards.*, COUNT(DISTINCT cheers.id) + COUNT(DISTINCT bookmarks.id) AS total_score")
      .order("total_score DESC, boards.created_at DESC")
      .limit(3)
      .includes(:user, :cheers, :bookmarks)

    if user_signed_in?
      @cheered_board_ids = current_user.cheers.where(board_id: @ranking_boards.map(&:id)).pluck(:board_id).to_set
      bookmarks = current_user.bookmarks.where(board_id: @ranking_boards.map(&:id))
      @bookmarks_map = bookmarks.index_by(&:board_id)
      @bookmarked_board_ids = @bookmarks_map.keys.to_set
    end
  end
end
