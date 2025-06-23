class BoardsController < ApplicationController
  def index
    @boards = Board.includes(:user)
  end

  def new
    @board = Board.new
  end

  def create
    @board = current_user.boards.build(board_params)
    if @board.save
      redirect_to boards_path, notice: "投稿が完了しました！"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def board_params
    params.require(:board).permit(:did_stretch, :content, :flexibility_level, :goal_id)
  end
end
