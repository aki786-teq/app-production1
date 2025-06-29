class Board < ApplicationRecord
  belongs_to :user
  belongs_to :goal

  has_one_attached :image

  validates :did_stretch, inclusion: { in: [true, false], message: "選択してください" }
  validates :content, length: { maximum: 1000 }, allow_blank: true
  validates :flexibility_level, numericality: { only_integer: true }, allow_nil: true

  # Exif除去 + リサイズ（800px以内）
  def display_image
    return unless image.attached?

    image.variant(
    resize_to_limit: [800, 800],
    saver: { strip: true } # Exif情報を削除
    ).processed
  end
end
