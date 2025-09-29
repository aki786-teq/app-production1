FactoryBot.define do
  factory :line_notification do
    association :user
    last_notified_at { nil }
  end
end
