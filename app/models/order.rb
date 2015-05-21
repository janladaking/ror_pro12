require 'active_merchant/billing/rails'

class Order < ActiveRecord::Base
  include TokenGenerator

  belongs_to :account
  has_one :billing_address, class_name: 'Address', as: :addressable, inverse_of: :addressable, dependent: :destroy
  accepts_nested_attributes_for :billing_address

  scope :inatec, -> { where(payment_method: 'inatec') }
  scope :baio, -> { where(payment_method: 'baio') }
  scope :not_baio, -> { where("payment_method != 'baio'") }
  scope :most_recent, -> { order('created_at DESC') }

  enum status: { created: 0, active: 1, inactive: 2, cancelled: 3, failed: 4 }
  serialize :info, Hash
  mount_uploader :invoice_file, InvoiceUploader
  attr_accessor :number, :year, :month, :verification_value, :ip

  monetize :subtotal_cents, disable_validation: true
  monetize :tax_cents, disable_validation: true
  monetize :total_cents, disable_validation: true

  validates :account, :plan, :plan_type, :plan_duration, :status, :payment_method, presence: true

  def plan
    Plan.by_plan_type(plan_type)
  end

  def tax_percentage
    tax_cents * 100.0 / subtotal_cents
  end

  def calculate_prices
    self.subtotal_cents = plan.price_cents[self.plan_duration]
    self.total_cents = ((subtotal_cents / 100.0) * Rails.application.secrets[:tax_percentage].to_f) + subtotal_cents
    self.tax_cents = total_cents - subtotal_cents
  end

  def create_payment!
    self.payment_method = 'inatec'
    self.card_brand = credit_card.brand
    self.last_4_digits = credit_card.display_number
    calculate_prices unless total_cents

    unless valid? && check_credit_card_validation
      self.status = :failed
      raise 'Order validation failed'
    end
    save!

    response = ::INATEC_GATEWAY.authorize_with_recurring(total_cents, credit_card, purchase_options)
    process_response(response)

    if active?
      inactive_others
      generate_invoice_and_send_mail
    else
      raise 'Not active payment'
    end
  end

  def self.generate_pdf(order_id)
    order = Order.find(order_id)
    return if order.baio_order?

    FileUtils.mkpath("tmp/orders")
    tmp_path = File.join("tmp/orders", order.invoice_filename)

    pdf_content = PdfCreator.render_invoice(order)
    File.open(tmp_path, 'wb'){|f| f.write pdf_content }

    order.invoice_file = File.open(tmp_path)
    order.save
    FileUtils.rm(tmp_path)

    AccountMailer.payment_success_mail(order.id).deliver
  end

  def invoice_id
    'VP7-%05d' % id
  end

  def invoice_filename
    "#{invoice_id}.pdf"
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def check_credit_card_validation
    success = true

    unless credit_card.valid?
      success = false

      credit_card.errors.each do |k,v|
        unless v.blank?
          errors.add(k, v.first)
          errors.add(:number, 'is invalid') if k == 'brand'
        end
      end
    end

    success
  end

  def baio_order?
    payment_method == 'baio'
  end

  def self.create_baio_order(account)
    order = account.orders.create plan_type: 'expert', plan_duration: Plan.free_plan_duration, status: :active, payment_method: 'baio', expired_at: 100.years.since
    order.inactive_others if order.persisted?
    order
  end

  def inactive_others
    account.orders.where('id != ?', id).active.update_all(status: Order.statuses[:inactive])
  end

  def self.inactive_expired
    Rails.logger.info "Order.inactive_expired: #{Date.today}"
    Order.not_baio.active.where('expired_at <= ?', Date.today).each do |order|
      order.inactive!

      # Restore unexpired inactive
      order.account.restore_unexpired_order
    end
  end

  private

  def process_response(response)
    if response.success?
      self.info = response.params
      self.transaction_id = response.params["transid"].first if self.transaction_id.blank?
      self.expired_at = self.plan_duration.months.since
      self.status = :active
      save!
    else
      self.status = :failed
      errors.add :base, response.message
      raise "Payment transaction failed: #{response.message}"
    end
  end

  def credit_card
    @credit_card ||= ActiveMerchant::Billing::CreditCard.new(
      first_name:         first_name,
      last_name:          last_name,
      month:              month,
      year:               year,
      verification_value: verification_value,
      number:             number
    )
  end

  def purchase_options
    raise 'Must be persisted' unless persisted?

    {
      order_id:     invoice_id,
      ip:           ip,
      first_name:   account.profile.first_name,
      last_name:    account.profile.last_name,
      description:  'Videopage7 plan purchase',
      email:        account.email,
      currency:     Rails.application.secrets[:currency_code],
      address: {
        zip:        billing_address.postal_code,
        street:     billing_address.address_1,
        city:       billing_address.city,
        country:    billing_address.billing_country
      }
    }
  end

  def generate_invoice_and_send_mail
    Order.delay.generate_pdf(self.id)
  end
end
