class Category < ActiveRecord::Base
  has_many :posts, dependent: :nullify
  validates_uniqueness_of :name

  def posts_for(account_id)
    self.posts.where(account_id: account_id)
  end

  def self.options_for_select
    Category.all.collect do |category|
      [category.id, category.name]      
    end
  end
end
