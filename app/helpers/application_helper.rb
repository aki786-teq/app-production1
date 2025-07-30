module ApplicationHelper
  def default_meta_tags
    {
      site: 'まいにち前屈',
      reverse: true,
      charset: 'utf-8',
      description: '柔軟運動が苦手、肩こり腰痛などの不調に悩まされている方など、めんどくさがりでも楽しく続けやすいをコンセプトに前屈ができるようストレッチをサポートします。',
      keywords: '前屈, 柔軟, 運動不足, ストレッチ, 肩こり, 腰痛, 健康管理',
      canonical: request.original_url,
      separator: '|',
      viewport: 'width=device-width, initial-scale=1',

      # Apple PWA関連のメタタグ
      'apple-mobile-web-app-capable' => 'yes',

      og: {
        site_name: 'まいにち前屈',
        title: 'まいにち前屈 - 毎日続けやすい柔軟運動アプリ',
        description: '柔軟運動が苦手、肩こり腰痛などの不調に悩まされている方など、めんどくさがりでも楽しく続けやすいをコンセプトに前屈ができるようストレッチをサポートします。',
        type: 'website',
        url: request.original_url,
        image: image_url('ogp.png'),
        locale: 'ja_JP'
      },
      twitter: {
        card: 'summary_large_image',
        creator: '@akikero786',
        title: 'まいにち前屈 - 毎日続けやすい柔軟運動アプリ',
        description: '柔軟運動が苦手、肩こり腰痛などの不調に悩まされている方など、めんどくさがりでも楽しく続けやすいをコンセプトに前屈ができるようストレッチをサポートします。',
        image: image_url('ogp.png')
      }
    }
  end

    # タイトルを動的に出力するメソッド
  def page_title(title = '')
    base_title = 'まいにち前屈'
    title.present? ? "#{title} | #{base_title}" : base_title
  end

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

  # YouTubeの動画リンクからビデオIDを抽出するメソッド
  def extract_youtube_video_id(link)
    # もしリンクが提供されていない場合、ビデオIDは存在しないので nil を返す
    return nil if link.nil? || link.empty?

    begin
      # URLを解析してビデオIDを取得する
      uri = URI(link) # リンクのURLをURIオブジェクトに変換

      # youtu.be形式の場合
      if uri.host == 'youtu.be'
        return uri.path[1..-1] # 先頭の/を除去
      end

      # youtube.com形式の場合
      if uri.host&.include?('youtube.com') && uri.query
        query = URI.decode_www_form(uri.query) # URLのクエリパラメータをデコードして取得
        query_hash = Hash[query] # クエリパラメータをハッシュに変換
        return query_hash["v"] # ハッシュからキー"v"に対応する値、ビデオIDを返す
      end

      nil
    rescue URI::InvalidURIError
      nil
    end
  end
end
