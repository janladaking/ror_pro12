require 'rails_helper'

describe ActiveMerchant::Billing::InatecGateway do
  before do
    ActiveMerchant::Billing::Base.mode = :test
  end

  let(:credit_card) do
    defaults = {
      number: "4242424242424242",
      month: 12,
      year: 2014,
      first_name: 'Muster',
      last_name: 'Mann',
      verification_value: '147',
      brand: 'visa'
    }
    ActiveMerchant::Billing::CreditCard.new(defaults)
  end

  let(:options) do
    {
      order_id: '1',
      ip: '10.0.0.1',
      first_name: 'Muster',
      last_name: 'Mann',
      description: 'ActiveMerchant Test Purchase',
      email: 'wow@example.com',
      currency: 'EUR',
      recurring_id: '123',
      address: {
        zip: '3301',
        street: 'Grants street',
        city: 'Kuldiga',
        country: 'LVA'
      }
    }
  end

  let(:credentials) do
    {
      merchant_id: 'bonofa_test',
      secret: '88a7',
      url_return: nil,
      # param_3d: 'always3d',
      custom1: '123456'
    }
  end

  let(:amount) { 101 }

  subject do
    ActiveMerchant::Billing::InatecGateway.new(credentials)
  end

  it '#authorize' do
    res = subject.authorize(amount, credit_card, options)
    pp res
    expect(res).to be_success

    transaction_id = res.params['transactionid'].first
    pp transaction_id

    # res = subject.capture(transaction_id: transaction_id)
    # pp res
    # expect(res).to be_success
  end

  it '#capture' do
    pending

    transaction_id = '58058910'
    res = subject.capture(transaction_id: transaction_id)
    pp res
    expect(res).to be_success
  end
end
