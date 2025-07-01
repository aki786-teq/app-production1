class Board < ApplicationRecord
  belongs_to :user
  belongs_to :goal

  has_one_attached :image

  validates :did_stretch, inclusion: { in: [true, false], message: "選択してください" }
  validates :content, length: { maximum: 1000 }, allow_blank: true
  validates :flexibility_level, numericality: { only_integer: true }, allow_nil: true

  validate :image_type
  validate :image_size

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
end
