class Board < ApplicationRecord
  belongs_to :user
  belongs_to :goal
  has_many :cheers, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :stretch_distances, dependent: :nullify
  has_one :notification, as: :subject, dependent: :destroy
  has_one_attached :image

  validates :did_stretch, inclusion: { in: [true, false], message: "選択してください" }
  validates :content, length: { maximum: 1000 }, allow_blank: true
  validates :flexibility_level, numericality: { only_integer: true }, allow_nil: true
  validate :image_type
  validate :image_size
  validate :youtube_link_format

  validates :item_name, length: { maximum: 255 }, allow_blank: true
  validates :item_price, numericality: { greater_than: 0 }, allow_nil: true
  validates :item_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
  validates :item_image_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  def image_type
    if image.attached? && !image.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:image, "はJPEG, PNG, WebP形式の画像のみ対応しています")
    end
  end

  def image_size
    if image.attached? && image.blob.byte_size > 1.megabytes
      errors.add(:image, "は1MB以下の画像を選んでください")
    end
  end

  # Exif除去 + リサイズ（800px以内）
  def display_image
    return unless image.attached?

    image.variant(
    resize_to_limit: [800, 800],
    saver: { strip: true } # Exif情報を削除
    ).processed
  end

  # ある投稿が特定のユーザによって応援されているか判定
  def cheered_by?(user)
    cheers.exists?(user_id: user.id)
  end

  def bookmarked_by?(user)
    bookmarks.exists?(user_id: user.id)
  end

  # YouTube リンクのフォーマットをチェック
  def youtube_link_format
    return if youtube_link.blank?

    # YouTube URLの正規表現パターン
    youtube_pattern = /\A(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/

    unless youtube_link.match(youtube_pattern)
      errors.add(:youtube_link, "は有効なYouTube URLを入力してください")
    end
  end

  # YouTube動画IDを取得
  def youtube_video_id
    return nil if youtube_link.blank?
    # YouTube URLから動画IDを抽出
    youtube_pattern = /(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/
    match = youtube_link.match(youtube_pattern)
    match ? match[1] : nil
  end

  # YouTube動画が添付されているかチェック
  def has_youtube_video?
    youtube_link.present? && youtube_video_id.present?
  end

  # 前屈測定結果が含まれているか
  def has_stretch_measurement?
    stretch_distances.exists?
  end
end
