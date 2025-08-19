FactoryBot.define do
  factory :stretch_distance do
    association :user
    flexibility_level { 'good' }
    comment_template { '良好な柔軟性です。' }
  end
end
