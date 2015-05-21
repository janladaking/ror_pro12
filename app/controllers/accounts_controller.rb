class AccountsController < ApplicationController
  skip_before_action :authenticate_account!, only: [:show, :videos, :imprint]
  before_filter :load_account

  layout 'bgwhite'

  def show
    set_tab :profile
    @profile = @account.profile
  end

  def follow
    current_account.follow(@account)
    redirect_to :back
  end

  def videos
    set_tab :videos
    @posts = @account.posts.published.order("created_at desc").page(params[:page]).per(12)
  end

  def unfollow
    current_account.stop_following(@account) if current_account.following?(@account)
    redirect_to :back
  end

  def imprint
    @page = @account.pages.find_by(slug: 'imprint')
  end

  private
    def load_account
      @account = Account.find(params[:id])
    end
  
end
