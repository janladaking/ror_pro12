class Plan
  BAIO_FOR_EXPERT = %w(vip_package pro_package).freeze
  DURATION_NAME = {
    1 => '1 month',
    12 => '1 year'
  }.freeze
  VALID_DURATIONS = DURATION_NAME.keys.freeze # months

  PLANS = {
    free: OpenStruct.new({
      active: false,
      upgrade_rating: 0,
      name: 'FREE',
      price_cents: {
        1 => 0,
        12 => 0,
      },
      post_limit: 5,
      post_category: false,
      blog_logo: false
    }),
    pro: OpenStruct.new({
      active: true,        # Can be purchased
      upgrade_rating: 10,  # Upgradable to plan with higher value
      name: 'PRO',         # Plan name
      price_cents: {       # Price per duration
        1 => 490,
        12 => 4900
      },
      post_limit: nil,     # Can post unlimited videos
      post_category: true, # Can put videos in the category "My successes"
      blog_logo: true      # Can upload a custom logo
    }),
    expert: OpenStruct.new({
      active: true,
      upgrade_rating: 100,
      name: 'EXPERT',
      price_cents: {
        1 => 649,
        12 => 6200
      },
      post_limit: nil,
      post_category: true,
      blog_logo: true
    })
  }.with_indifferent_access.freeze

  def self.by_plan_type(plan_type)
    PLANS[plan_type]
  end

  def self.free_plan
    by_plan_type(:free)
  end

  def self.free_plan_duration
    -1
  end

  def self.pro_plan
    by_plan_type(:pro)
  end

  def self.expert_plan
    by_plan_type(:expert)
  end

end
