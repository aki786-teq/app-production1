class Board < ApplicationRecord
  belongs_to :user
  belongs_to :goal

  has_one_attached :image

  validates :did_stretch, inclusion: { in: [true, false] }, presence: true
  validates :content, length: { maximum: 1000 }, allow_blank: true
  validates :flexibility_level, numericality: { only_integer: true }, allow_nil: true

  # Exif除去 + リサイズ（800px以内）
  def display_image
    return unless image.attached?

    image.variant(
      combine_options: {
        auto_orient: true,
        strip: true,
        resize: "800x800>"
      }
    ).processed
  end
end
