require 'rails_helper'

RSpec.describe Plan, type: :model do
  it 'PLANS' do
    pp Plan::PLANS
  end

  it '.free_plan' do
    plan = Plan.free_plan
    pp plan
    expect(plan[:price_cents][1]).to eq 0
    expect(plan['price_cents'][1]).to eq 0
    expect(plan.price_cents[1]).to eq 0
  end

  it '.pro_plan' do
    expect(Plan.pro_plan).to be_present
  end
end
