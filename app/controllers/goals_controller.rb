class GoalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_goal, only: [ :edit, :update ]

  def new
    if current_user.goal
      redirect_to edit_goal_path, danger: t("goals.flash_message.already_exists")
    else
      @goal = current_user.build_goal
    end
  end

  def create
    @goal = current_user.build_goal(goal_params)
    if @goal.save
      redirect_to edit_goal_path, success: t("goals.flash_message.create_success")
    else
      flash.now[:danger] = t("goals.flash_message.create_failure")
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @goal.update(goal_params)
      redirect_to edit_goal_path, success: t("goals.flash_message.update_success")
    else
      flash.now[:danger] = t("goals.flash_message.update_failure")
      render :edit, status: :unprocessable_entity
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
