class ProfilesController < ApplicationController
  skip_before_action :authenticate_account!
  
  layout 'bgwhite'
  
  def show
    @account = @current_author
    @profile = @current_author.profile
  end
  
end
