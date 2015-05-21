FactoryGirl.define do
  factory :account do
    email { Faker::Internet.email }
    password 'defaultpw'

    after(:create) do |account|
      account.profile.update! first_name: Faker::Name.first_name, last_name: Faker::Name.last_name
    end
  end
end
