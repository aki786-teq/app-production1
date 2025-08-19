FactoryBot.define do
  factory :line_link_token do
    sequence(:token) { |n| "token-#{n}" }
    messaging_user_id { "Uxxxxxxxx" }
    expires_at { 1.hour.from_now }
    consumed_at { nil }
  end
end
