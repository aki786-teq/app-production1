FactoryBot.define do
  factory :line_notification do
    association :user
    consecutive_inactive_days { 0 }
    last_notified_at { nil }
  end
end
