class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @boards = @user.boards.order(created_at: :desc)
  end
end
