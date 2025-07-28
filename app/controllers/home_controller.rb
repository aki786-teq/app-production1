class HomeController < ApplicationController
  def index
    start_time = 6.days.ago.beginning_of_day
    end_time = 1.day.ago.end_of_day

    @ranking_boards = Board
      .left_joins(:cheers, :bookmarks)
      .where(created_at: start_time..end_time)
      .group("boards.id")
      .select("boards.*, COUNT(DISTINCT cheers.id) + COUNT(DISTINCT bookmarks.id) AS total_score")
      .order("total_score DESC, boards.created_at DESC")
      .limit(3)
      .includes(:user)
  end
end
