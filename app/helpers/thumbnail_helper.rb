require "google/apis/youtube_v3"

module ThumbnailHelper
  def youtube_thumbnail(video_id, options = {})
    require "google/apis/youtube_v3"
    options = { show_info: true }.merge(options)

    # キャッシュの設定を変更する（1日間）
    Rails.cache.fetch("youtube_thumbnail_#{video_id}", expires_in: 1.day) do
      service = Google::Apis::YoutubeV3::YouTubeService.new
      service.key = ENV["YOUTUBE_API_KEY"]

      begin
        # ビデオの詳細情報（snippet, statistics）を取得
        video_response = service.list_videos("snippet,statistics", id: video_id)
        video_item = video_response.items.first

        if video_item
          thumbnail_url = video_item.snippet.thumbnails.maxres&.url ||
                         video_item.snippet.thumbnails.high&.url ||
                         video_item.snippet.thumbnails.medium&.url
          title = video_item.snippet.title
          view_count = video_item.statistics&.view_count || "N/A"
          upload_date = video_item.snippet.published_at.to_date.strftime("%Y/%m/%d")

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
      rescue => e
        Rails.logger.error "YouTube API Error: #{e.message}"
        content_tag(:div, "動画の読み込みに失敗しました", class: "text-center")
      end
    end
  end
end
