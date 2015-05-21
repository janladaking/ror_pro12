require 'rails_helper'

RSpec.describe Account, type: :model do
  subject do
    create :account
  end

  it 'subject' do
    pp subject
    expect(subject).to be_a described_class
  end

  it '#profile' do
    pp subject.profile
    expect(subject.profile).to be_a AccountProfile
  end

  describe '#current_plan' do
    it 'free' do
      expect(subject.current_plan).to eq Plan.free_plan
    end

    it 'inactive' do
      s1 = create :order, account: subject, status: :inactive
      expect(subject.current_plan).to eq Plan.free_plan
    end

    it 'active' do
      s1 = create :order, account: subject, status: :active
      expect(subject.current_plan).to eq s1.plan
    end
  end

  it '#apply_referrer_code!' do
    subject.bonofa_partner_account_id = nil
    subject.apply_referrer_code! 'bonofa'
    expect(subject.bonofa_partner_account_id).to eq 1
  end

  describe '.from_omniauth' do
    let(:info) { OpenStruct.new baio_package: Plan::BAIO_FOR_EXPERT.first }
    let(:auth) { OpenStruct.new provider: 'bonofa', uid: '1', info: info }

    before(:each) {
      subject.authentications.create! provider: 'bonofa', uid:  '1', token: '111'
    }

    it 'baio partner get expert plan' do
      a1 = Account.from_omniauth(auth) # upgrade
      expect(subject).to eq a1
      expect(subject.current_plan).to eq Plan.expert_plan

      info.baio_package = 'bad'
      Account.from_omniauth(auth) # downgrade
      expect(subject.current_plan).to eq Plan.free_plan
    end

    it 'not baio partner downgrade' do
      subject.orders.create! plan_type: 'pro', plan_duration: 12, status: :active, payment_method: 'inatec', expired_at: 1.years.since
      expect(subject.current_plan).to eq Plan.pro_plan

      Order.create_baio_order(subject)
      expect(subject.current_plan).to eq Plan.expert_plan

      info.baio_package = 'bad'
      Account.from_omniauth(auth) # downgrade
      expect(subject.current_plan).to eq Plan.pro_plan
    end
  end

  it '#restore_unexpired_order' do
    a1 = create :account
    o0 = create :order, account: a1, expired_at: 2.days.ago, status: :inactive
    o1 = create :order, account: a1, expired_at: 1.days.since, status: :inactive
    o2 = create :order, account: a1, expired_at: 3.days.ago, status: :inactive

    a1.restore_unexpired_order
    expect(a1.active_order).to eq o1
  end

  it '.check_upgrade_plan!' do
    subject.orders.create! plan_type: 'pro', plan_duration: 12, status: :active, payment_method: 'inatec', expired_at: 1.years.since
    expect(subject.current_plan).to eq Plan.pro_plan
    expect(subject.current_duration).to eq 12

    expect { subject.check_upgrade_plan!(Plan.pro_plan, 1) }.to raise_error
    expect { subject.check_upgrade_plan!(Plan.pro_plan, 12) }.to raise_error

    expect { subject.check_upgrade_plan!(Plan.expert_plan, 1) }.to_not raise_error
    expect { subject.check_upgrade_plan!(Plan.expert_plan, 12) }.to_not raise_error

    subject.orders.destroy_all
    subject.orders.create! plan_type: 'pro', plan_duration: 1, status: :active, payment_method: 'inatec', expired_at: 1.years.since

    expect { subject.check_upgrade_plan!(Plan.pro_plan, 1) }.to raise_error
    expect { subject.check_upgrade_plan!(Plan.pro_plan, 12) }.to_not raise_error
  end
end
