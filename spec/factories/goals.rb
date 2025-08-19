FactoryBot.define do
  factory :goal do
    goal { "床に指がつく" }
    content { "毎日3分ストレッチ" }
    association :user
  end
end
