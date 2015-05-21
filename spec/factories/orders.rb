FactoryGirl.define do
  factory :order do
    account
    plan_type 'pro'
    plan_duration 12

    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    ip '127.0.0.1'
    number '4149011500000147'
    year 2014
    month 12
    verification_value 147

    payment_method 'inatec'
    # info
    # transaction_id
    # invoice_file
    # card_brand
    # last_4_digits
    expired_at { 1.year.since }

    after(:build) do |order|
      order.calculate_prices
      order.billing_address ||= build(:address, addressable: order)
    end
  end
end
