class SessionsController < Devise::SessionsController
  before_filter :redirect_to_www
  def redirect_to_www
    if request.subdomain != "www"
      if Rails.env.production?
        redirect_to edit_admin_setting_url(host: "www.#{request.domain}")
      elsif request.subdomain.present?
        redirect_to edit_admin_setting_url(host: "www.#{request.domain}")
      end
    end
  end
end
