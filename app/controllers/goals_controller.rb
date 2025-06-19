class GoalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_goal, only: [:edit, :update]

  def new
    if current_user.goal
      redirect_to edit_goal_path
    else
      @goal = current_user.build_goal
    end
  end

  def create
    @goal = current_user.build_goal(goal_params)
    if @goal.save
      redirect_to edit_goal_path, notice: "ストレッチ目標を設定しました"
    else
      render :new
    end
  end

  def edit; end

  def update
    if @goal.update(goal_params)
      redirect_to edit_goal_path, notice: "ストレッチ目標を更新しました"
    else
      render :edit
    end
  end

  private

  def set_goal
    @goal = current_user.goal
  end

  def goal_params
    params.require(:goal).permit(:goal, :content, :reward, :punishment)
  end
end
