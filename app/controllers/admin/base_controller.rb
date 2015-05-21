class Admin::BaseController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_account!


  before_filter :restrict_access

  layout 'admin'

  private

  def restrict_access
    if request.subdomain.present? && request.subdomain != "www"
      if current_account.setting.blank? || current_account.setting.blog_alias!=request.subdomain
        raise ActionController::RoutingError.new('Not Found')
      end
    end
  end

end
