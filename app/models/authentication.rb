class Authentication < ActiveRecord::Base
  belongs_to :account
  validates_uniqueness_of :uid, :scope => :provider
end
