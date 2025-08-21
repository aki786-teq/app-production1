FactoryBot.define do
  factory :line_link_token do
    token { SecureRandom.urlsafe_base64(24) }
    messaging_user_id { "U#{SecureRandom.hex(8)}" }
    expires_at { 30.minutes.from_now }
    consumed_at { nil }
    user_id { nil }
  end
end
