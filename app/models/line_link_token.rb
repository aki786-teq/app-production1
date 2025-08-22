class LineLinkToken < ApplicationRecord
  belongs_to :user, optional: true

  validates :token, presence: true, uniqueness: true
  validates :messaging_user_id, presence: true

  scope :valid_unconsumed, -> { where("expires_at > ? AND consumed_at IS NULL", Time.current) }

  def consumed?
    consumed_at.present?
  end

  def consume!(user:)
    transaction do
      update!(consumed_at: Time.current, user_id: user.id)
    end
  end
end
