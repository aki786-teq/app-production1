FactoryBot.define do
  factory :board do
    did_stretch { true }
    content { "きょうもがんばった" }
    flexibility_level { 1 }
    association :user
    association :goal
  end
end
