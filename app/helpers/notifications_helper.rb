module NotificationsHelper
  def transition_path(notification)
    case notification.action_type.to_sym
    when :cheer
      board_path(notification.subject.board)
    else
      root_path
    end
  end
end
