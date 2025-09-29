class LineLinkToken < ApplicationRecord
  belongs_to :user, optional: true

  validates :token, presence: true, uniqueness: true
  validates :messaging_user_id, presence: true

  # 有効期限内かつ未使用のトークンだけを絞り込む
  scope :valid_unconsumed, -> { where("expires_at > ? AND consumed_at IS NULL", Time.current) }

  # 使用済み判定
  def consumed?
    consumed_at.present?
  end

  # トークンを「使用済み」として確定
  def consume!(user:)
    update!(consumed_at: Time.current, user_id: user.id)
  end
end
