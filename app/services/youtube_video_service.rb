require "google/apis/youtube_v3"

class YoutubeVideoService
  def self.fetch_video_info(video_id)
    Rails.cache.fetch("youtube_thumbnail_#{video_id}", expires_in: 1.day) do
      service = Google::Apis::YoutubeV3::YouTubeService.new
      service.key = ENV["YOUTUBE_API_KEY"]

      begin
        # ビデオの詳細情報（snippet, statistics）を取得
        video_response = service.list_videos("snippet,statistics", id: video_id)
        video_item = video_response.items.first

        if video_item
          {
            title: video_item.snippet.title,
            thumbnail_url: video_item.snippet.thumbnails.maxres&.url ||
                          video_item.snippet.thumbnails.high&.url ||
                          video_item.snippet.thumbnails.medium&.url,
            view_count: video_item.statistics&.view_count || 0,
            upload_date: video_item.snippet.published_at.to_date.strftime("%Y/%m/%d"),
            channel_title: video_item.snippet.channel_title
          }
        else
          nil
        end
      rescue => e
        Rails.logger.error "YouTube API Error: #{e.class} - #{e.message}"
        nil
      end
    end
  end
end
