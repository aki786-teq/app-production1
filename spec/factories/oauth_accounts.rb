FactoryBot.define do
  factory :oauth_account do
    association :user
    provider { "line_messaging" }
    sequence(:uid) { |n| "uid_#{n}" }
    auth_data { {} }
  end
end
