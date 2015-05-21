FactoryGirl.define do
  factory :address do
    # addressable { create :account }
    address_1 { Faker::Address.street_address }
    address_2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state { Faker::AddressUS.state }
    postal_code { Faker::AddressUS.zip_code }
    country_code { Faker::Address.country_code }
  end
end
