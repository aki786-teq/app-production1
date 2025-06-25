class BoardsController < ApplicationController
  def index
    @boards = Board.includes(:user).order(created_at: :desc)
  end

  def new
    @board = Board.new
  end

  def create
    @board = current_user.boards.build(board_params)

    if current_user.goal.present?
      @board.goal = current_user.goal
      @board.goal_title     = current_user.goal.goal
      @board.goal_content   = current_user.goal.content
      @board.goal_reward    = current_user.goal.reward
      @board.goal_punishment = current_user.goal.punishment
    end

    if @board.save
      redirect_to boards_path, notice: "投稿が完了しました！"
    else
      Rails.logger.debug(@board.errors.full_messages)
      render :new, status: :unprocessable_entity
    end
  end

  def show
  @board = Board.find(params[:id])
  end

  private

  def board_params
    permitted = params.require(:board).permit(:did_stretch, :content, :flexibility_level, :goal_id, :image)
    permitted[:did_stretch] = ActiveModel::Type::Boolean.new.cast(permitted[:did_stretch])
    permitted
  end
end
