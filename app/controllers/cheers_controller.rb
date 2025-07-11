class CheersController < ApplicationController
  def create
    board = Board.find(params[:board_id])
    cheer = current_user.cheers.new(board_id: board.id)
    cheer.save

    respond_to do |format|
      format.html { redirect_to request.referer }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "cheer-button-#{board.id}",
          partial: "cheers/btn",
          locals: { board: board }
        )
      end
    end
  end

  def destroy
    board = Board.find(params[:board_id])
    cheer = current_user.cheers.find_by(board_id: board.id)
    cheer.destroy

    respond_to do |format|
      format.html { redirect_to request.referer }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "cheer-button-#{board.id}",
          partial: "cheers/btn",
          locals: { board: board }
        )
      end
    end
  end
end
