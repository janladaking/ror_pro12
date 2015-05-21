class PagesController < ApplicationController
  skip_before_action :authenticate_account!
  skip_before_filter :restrict_access

  def imprint
  end

  def terms_and_conditions
  end

  def promotion
    @posts = Post.all.published.order("created_at desc").limit(20)
  end

  def show
  end
end
