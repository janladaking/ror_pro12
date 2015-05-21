require 'rails_helper'

RSpec.describe Address, type: :model do
  subject do
    create :address, addressable: create(:account)
  end

  it 'subject' do
    pp subject
    expect(subject).to be_a described_class
  end

  describe "#country_name" do
    it "returns country_name as a string" do
      address = build(:address, country_code: 'CN')
      address.country_name.should eq('China')
    end

    it "returns nil if country is wrong" do
      address = build(:address, country_code: 'abcd')
      address.country_name.should eq(nil)
    end
  end

  describe "#billing_country" do
    it "returns activemerchant country_name as a string" do
      address = build(:address, country_code: 'CN')
      address.billing_country.should eq('CHN')
    end

    it "returns nil if country is wrong" do
      address = build(:address, country_code: 'abcd')
      address.billing_country.should eq('')
    end
  end
end
