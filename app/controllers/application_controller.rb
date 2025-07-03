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
    # Deviseのログアウト時は許可
  return if controller_path == "devise/sessions" && action_name == "destroy"

  # goal#newまたはcreateアクションの場合は許可
  if controller_name == "goals" && %w[new create].include?(action_name)
    return
  end

    goal = current_user.goal
    # 目標が存在しない、または goal/contentが未入力なら、編集ページ含めすべて制限
    if goal.blank? || goal.goal.blank? || goal.content.blank?
      redirect_to new_goal_path, danger: t("goals.flash_message.setup_required")
    end
  end
end
