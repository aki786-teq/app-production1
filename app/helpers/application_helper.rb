module ApplicationHelper
  def flash_background_color(type)
    case type.to_sym
    when :notice, :success
      "bg-green-100 text-green-700"
    when :alert, :danger
      "bg-red-100 text-red-700"
    else
      "bg-gray-100 text-gray-700"
    end
  end
end
