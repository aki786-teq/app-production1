class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :ensure_correct_user, only: [:edit_profile, :update_profile]

  def show
    @boards = @user.boards.order(created_at: :desc)
  end

  def edit_profile
  end

  def update_profile
    if @user.update(profile_params)
      redirect_to user_path(@user), success: 'プロフィールが更新されました。'
    else
      render :edit_profile, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def ensure_correct_user
    redirect_to root_path unless @user == current_user
  end

  def profile_params
    params.require(:user).permit(:name, :introduce)
  end
end