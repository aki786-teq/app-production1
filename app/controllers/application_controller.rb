class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :require_goal_setup, if: :user_signed_in?
  allow_browser versions: :modern
  add_flash_types :success, :danger

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  private
  def require_goal_setup
    return if controller_name == "goals" && %w[new create edit update].include?(action_name)
    return if controller_path == "devise/sessions" && action_name == "destroy"

    goal = current_user.goal
    if goal.blank? || goal.goal.blank? || goal.content.blank?
      redirect_to new_goal_path
    end
  end
end
