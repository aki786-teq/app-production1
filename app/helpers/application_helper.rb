module ApplicationHelper
  def flash_background_color(type)
    case type.to_sym
    when :notice, :success
      "bg-green-100 text-green-700"
    when :alert, :danger
      "bg-red-100 text-red-700"
    else
      "bg-stone-100 text-stone-700"
    end
  end

  # fontawesomeのアイコンを生成するメソッド
  def icon(icon_style, icon_name)
    tag.i(class: ["fa-#{icon_style}", "fa-#{icon_name}"])
  end

  # fontawesomeの「アイコン＋文字列」を生成するメソッド
  def icon_with_text(icon_style, icon_name, text)
    tag.span(icon(icon_style, icon_name), class: "mr-2") + tag.span(text)
  end
end
