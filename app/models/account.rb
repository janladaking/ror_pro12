class Account < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  acts_as_commontator
  acts_as_followable
  acts_as_follower

  has_many :posts, dependent: :destroy
  has_many :videos, dependent: :destroy
  has_many :authentications, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :pages, dependent: :destroy

  has_one :setting, class_name: 'AccountSetting', dependent: :destroy
  has_one :profile, class_name: 'AccountProfile', inverse_of: :account, dependent: :destroy

  accepts_nested_attributes_for :profile

  after_create :generate_setting
  after_create :generate_profile
  after_create :generate_default_pages

  def full_name
    return "#{self.profile.first_name} #{self.profile.last_name}" if self.profile.present?
    "Unknown"
  end

  def active_order
    orders.active.first
  end

  def current_plan
    active_order.try(:plan) || Plan.free_plan
  end

  def current_duration
    active_order.try(:plan_duration) || Plan.free_plan_duration
  end

  def blog_alias
    self.setting.blog_alias.strip
  end

  def self.from_omniauth(auth, referrer_code = nil)
    Rails.logger.debug { auth.to_hash }
    account = Authentication.where(provider: auth[:provider], uid: auth[:uid]).first.try(:account) || create_from_omniauth(auth, referrer_code)

    if auth.info
      if account.promotion_code != auth.info.promotion_code
        account.update promotion_code: auth.info.promotion_code
      end

      if auth.provider.to_s == 'bonofa'
        if Plan::BAIO_FOR_EXPERT.include? auth.info.baio_package
          # Upgrade
          unless account.active_order.try :baio_order?
            Order.create_baio_order(account)
          end
        elsif account.active_order.try :baio_order?
          # Downgrade
          account.active_order.cancelled!

          # Restore unexpired inactive
          account.restore_unexpired_order
        end
      end
    end

    account
  end

  def apply_referrer_code!(referrer_code)
    if referrer_code.present? && promotion_code != referrer_code
      response = RestClient.get "https://shop.bonofa.com/api/v1/promo_code/#{referrer_code}"
      json = MultiJson.load(response)
      if json['code'] == 'OK'
        update bonofa_partner_account_id: json['account_id']
      end
    end
  rescue => ex
    Rails.logger.error ex.inspect
    Rails.logger.error ex.backtrace.join("\n")
  end

  def self.create_from_omniauth(auth, referrer_code)
    unless account = Account.find_by_email(auth["info"]["email"])
      password = Devise.friendly_token[0,20]
      account = Account.create(
        email:                  auth.info.email,
        password:               password,
        password_confirmation:  password,
      )

      if referrer_code.present?
        account.apply_referrer_code!(referrer_code)
      end

      profile = account.profile
      profile.first_name = auth.info.first_name
      profile.last_name = auth.info.last_name
      profile.save
    end

    account.authentications.build(
      provider: auth["provider"],
      uid:  auth["uid"],
      token: auth["credentials"]["token"]
    )
    account.save
    account
  end

  def restore_unexpired_order
    orders.not_baio.inactive.most_recent.each do |recent|
      if recent.expired_at && recent.expired_at > Date.today
        recent.active!
        return
      end
    end
  end

  def posts_for(status)
    if status == 'all'
      @posts = self.posts
    elsif status == 'trash'
      @posts = self.posts.only_deleted
    else
      @posts = self.posts.where(status: status)
    end
  end

  def generate_setting
    self.create_setting(blog_alias: Time.now.to_i, blog_enabled: false)
  end

  def generate_profile
    self.create_profile unless profile
  end

  def generate_default_pages
    self.pages.create(slug: 'imprint', title: 'Imprint', content: '')
  end

  def check_upgrade_plan!(new_plan, new_duration)
    new_duration = new_duration.to_i

    if active_order.try :baio_order?
      raise "Can't upgrade plan"
    end

    unless new_plan.try :active
      raise 'Bad or inactive plan'
    end

    if new_plan.upgrade_rating < current_plan.upgrade_rating
      raise "Can't downgrade plan"
    end

    unless Plan::VALID_DURATIONS.include?(new_duration)
      raise 'Bad plan duration'
    end

    if new_plan == current_plan
      if new_duration == current_duration
        raise 'Plan/duration already active'
      elsif new_duration < current_duration
        raise "Can't downgrade plan duration"
      end
    end
  end

  def upgrade_plan_status(new_plan, new_duration)
    if active_order.try :baio_order?
      :cannot_upgrade
    elsif new_plan == current_plan && new_duration == current_duration
      :current
    elsif new_plan == current_plan && new_duration < current_duration
      :cannot_upgrade
    elsif !new_plan.active || new_plan.upgrade_rating < current_plan.upgrade_rating
      :cannot_upgrade
    else
      :can_upgrade
    end
  end

  def can_create_post?
    current_plan.post_limit.nil? || current_plan.post_limit > posts.count
  end

  def can_use_post_category?
    !!current_plan.post_category
  end

  def can_upload_blog_logo?
    !!current_plan.blog_logo
  end
end
