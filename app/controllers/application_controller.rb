class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate_account!
  
  before_filter :restrict_access
  before_filter :load_current_author

  helper_method :current_blog_setting

  def load_current_author
    @current_author = @account_setting.try(:account)
    @current_author ||= current_account
    return @current_author
  end

  def current_author
    @current_author
  end

  def current_user
    current_account
  end

  private

  def current_blog_setting
    @account_setting
  end

  def restrict_access
    if request.subdomain.present? && request.subdomain != "www"
      @account_setting = AccountSetting.where(blog_alias: request.subdomain.downcase).first
      raise ActionController::RoutingError.new('Not Found') if @account_setting.blank?
    end
  end

  def after_sign_in_path_for(resource_or_scope)
    posts_path
  end

end
