FactoryBot.define do
  factory :maintenance_service do
    association :vehicle
    description { "Oil change and filter replacement" }
    status { :pending }
    date { Date.current }
    cost_cents { rand(5000..50000) }
    priority { :medium }
    completed_at { nil }

    trait :pending do
      status { :pending }
      completed_at { nil }
    end

    trait :in_progress do
      status { :in_progress }
      completed_at { nil }
    end

    trait :completed do
      status { :completed }
      completed_at { 1.day.ago }
    end

    trait :low_priority do
      priority { :low }
    end

    trait :medium_priority do
      priority { :medium }
    end

    trait :high_priority do
      priority { :high }
    end

    trait :expensive do
      cost_cents { rand(100000..500000) }
    end

    trait :cheap do
      cost_cents { rand(1000..5000) }
    end

    trait :past do
      date { rand(1..30).days.ago.to_date }
    end
  end
end