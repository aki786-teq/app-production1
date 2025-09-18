class ReminderSettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @line_notification = current_user.line_notification_setting
  end
end
