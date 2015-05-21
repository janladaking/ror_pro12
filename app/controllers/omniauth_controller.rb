class OmniauthController < ApplicationController
  skip_before_action :authenticate_account!
  skip_before_action :verify_authenticity_token

  def create
    @account = Account.from_omniauth(env['omniauth.auth'], session[:referrer_code])

    if @account.persisted? && session[:referrer_code].present?
      session[:referrer_code] = nil
    end

    sign_in @account
    redirect_to posts_path
  end
end
