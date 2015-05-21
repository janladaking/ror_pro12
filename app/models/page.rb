class Page < ActiveRecord::Base
  include Bootsy::Container
  validates :account_id, presence: true
  validates_uniqueness_of :slug, :scope => [:account_id]

  belongs_to :account
end