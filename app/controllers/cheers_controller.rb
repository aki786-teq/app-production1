class CheersController < ApplicationController
  def create
    board = Board.find(params[:board_id])
    cheer = current_user.cheers.new(board_id: board.id)
    cheer.save
    redirect_to request.referer
  end

  def destroy
    board = Board.find(params[:board_id])
    cheer = current_user.cheers.find_by(board_id: board.id)
    cheer.destroy
    redirect_to request.referer
  end
end
