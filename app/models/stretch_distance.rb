class StretchDistance < ApplicationRecord
  belongs_to :user
  belongs_to :board, optional: true

  COMMENT_TEMPLATES = {
    excellent: [
      "素晴らしい柔軟性です！さらに高みを目指していきましょう。",
      "非常に良い結果です。継続的なストレッチの成果が現れています。",
      "理想的な前屈レベルです。この調子で柔軟性を維持していきましょう。"
    ],
    good: [
      "良好な柔軟性です。もう少しで床に手が届きそうですね。",
      "もう少しで床に届きそうです。日々のストレッチが効いています。",
      "順調に改善しています。継続することで更なる向上が期待できます。"
    ],
    average: [
      "伸び代があります。定期的なストレッチで改善していきましょう。",
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
    'average' => '普通',
    'needs_improvement' => '要改善'
  }.freeze

  validates :flexibility_level, presence: true

  before_save :set_flexibility_data

  def localized_flexibility_level
    FLEXIBILITY_LEVEL_JA[flexibility_level] || flexibility_level
  end

  private

  def set_flexibility_data
    self.comment_template = generate_comment
  end

  def generate_comment
    return nil unless flexibility_level.present?
    templates = COMMENT_TEMPLATES[flexibility_level.to_sym]
    templates&.sample
  end
end
