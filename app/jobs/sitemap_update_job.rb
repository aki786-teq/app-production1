class SitemapUpdateJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "サイトマップの更新を開始します"

    begin
      # サイトマップを生成
      SitemapGenerator::Sitemap.verbose = false
      SitemapGenerator::Sitemap.create

      Rails.logger.info "サイトマップの更新が完了しました"
    rescue => e
      Rails.logger.error "サイトマップの更新中にエラーが発生しました: #{e.message}"
      raise e
    end
  end
end
