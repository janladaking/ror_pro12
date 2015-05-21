class PublicController < ApplicationController
  def index
    # intro text
  end

  def show
    @post = Post.where(:id => params[:id]).first
    redirect_to(:action => 'index') unless @post
  end
  
end
