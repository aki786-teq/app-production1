module ThumbnailHelper
  def youtube_thumbnail(video_id, options = {})
    options = { show_info: true }.merge(options)

    # 動画情報を取得
    video_info = YoutubeVideoService.fetch_video_info(video_id)

    if video_info
      thumbnail_url = video_info[:thumbnail_url]
      title = video_info[:title]
      view_count = video_info[:view_count]
      upload_date = video_info[:upload_date]

      content = content_tag(:div, class: "text-center") do
        image_tag(thumbnail_url, alt: title, **options) +
        if options[:show_info]
          content_tag(:div, class: "video-info") do
            content_tag(:p, raw("#{title}<br>#{number_with_delimiter(view_count)} 回視聴 #{upload_date} 公開"))
          end
        end
      end
      content
    else
      # ビデオが見つからない場合の処理
      content_tag(:div, "動画が見つかりません", class: "text-center")
    end
  end
end
