FactoryBot.define do
  factory :vehicle do
    sequence(:vin) { |n| "1HGBH41JXMN#{n.to_s.rjust(6, '0')}" }
    sequence(:plate) { |n| "MEX-#{n.to_s.rjust(4, '0')}" }
    brand { %w[Toyota Honda Ford Chevrolet Nissan Volkswagen].sample }
    model { %w[Sedan Pickup SUV Hatchback Van].sample }
    year { rand(2015..2024) }
    status { :active }

    trait :inactive do
      status { :inactive }
    end

    trait :in_maintenance do
      status { :in_maintenance }
    end

    trait :old do
      year { rand(1990..2000) }
    end

    trait :new do
      year { rand(2023..2024) }
    end
  end
end