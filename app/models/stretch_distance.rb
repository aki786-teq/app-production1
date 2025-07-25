class StretchDistance < ApplicationRecord
  belongs_to :user
  belongs_to :board, optional: true

  attr_accessor :pixel_distance

  COMMENT_TEMPLATES = {
    excellent: [
      "素晴らしい柔軟性です！床に手がつく状態をキープできていますね。",
      "非常に良い結果です。継続的なストレッチの成果が現れています。",
      "理想的な前屈レベルです。この調子で柔軟性を維持していきましょう。"
    ],
    good: [
      "良好な柔軟性です。もう少しで床に手が届きそうですね。",
      "平均以上の結果です。日々のストレッチが効いています。",
      "順調に改善しています。継続することで更なる向上が期待できます。"
    ],
    average: [
      "平均的な柔軟性です。定期的なストレッチで改善していきましょう。",
      "まずまずの結果です。毎日少しずつでも続けることが大切です。",
      "標準的なレベルです。無理をせず徐々に柔軟性を高めていきましょう。"
    ],
    needs_improvement: [
      "改善の余地があります。焦らずゆっくりとストレッチを続けましょう。",
      "これから柔軟性向上の取り組みを継続していきましょう。",
      "毎日のストレッチ習慣を作ることから始めてみましょう。"
    ]
  }.freeze

  FLEXIBILITY_LEVEL_JA = {
    'excellent' => '優秀',
    'good' => '良好',
    'average' => '平均',
    'needs_improvement' => '要改善'
  }.freeze

  validates :distance_cm, presence: true,
            numericality: { greater_than_or_equal_to: -50, less_than_or_equal_to: 100 }
  validates :height_cm, presence: true,
            numericality: { greater_than: 50, less_than: 250 }

  before_save :convert_distance_to_cm, if: -> { distance_cm.blank? && pixel_distance.present? }
  before_save :set_flexibility_data

  def localized_flexibility_level
    FLEXIBILITY_LEVEL_JA[flexibility_level] || flexibility_level
  end

  private

  def convert_distance_to_cm
    head_to_heel_px = 400.0
    scale = height_cm / head_to_heel_px
    self.distance_cm = pixel_distance * scale
  end

  def set_flexibility_data
    self.flexibility_level = calculate_flexibility_level
    self.comment_template = generate_comment
  end

  def calculate_flexibility_level
    case distance_cm
    when -Float::INFINITY..0
      'excellent'
    when 0..10
      'good'
    when 10..20
      'average'
    else
      'needs_improvement'
    end
  end

  def generate_comment
    return nil unless flexibility_level.present?
    templates = COMMENT_TEMPLATES[flexibility_level.to_sym]
    templates&.sample
  end
end