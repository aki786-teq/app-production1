SitemapGenerator::Sitemap.default_host = "https://mainichi-zenkutsu.jp"

# サイトマップの保存場所を設定
SitemapGenerator::Sitemap.public_path = 'public/'

# サイトマップのファイル名を設定
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'

SitemapGenerator::Sitemap.create do
  # トップページ
  add root_path, :changefreq => 'daily', :priority => 1.0

  # 利用規約・プライバシーポリシーページ
  add terms_of_service_static_path, :changefreq => 'monthly', :priority => 0.3
  add privacy_policy_static_path, :changefreq => 'monthly', :priority => 0.3

  # 投稿一覧ページ
  add boards_path, :changefreq => 'daily', :priority => 0.8

  # 個別の投稿ページ（過去1週間の投稿のみ）
  Board.where(created_at: 1.week.ago..Time.current).find_each do |board|
    add board_path(board), :lastmod => board.updated_at, :changefreq => 'weekly', :priority => 0.6
  end
end
