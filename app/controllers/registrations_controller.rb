class RegistrationsController < Devise::RegistrationsController

  # GET /p/:referrer_code
  def promolink
    unless current_account
      session[:referrer_code] = params[:referrer_code]
      redirect_to root_path
    else
      redirect_to posts_path
    end
  end

  def create
    devise_parameter_sanitizer.for(:sign_up) << { profile_attributes: [:first_name, :last_name] }
    super

    if resource.persisted? && session[:referrer_code].present?
      resource.apply_referrer_code!(session[:referrer_code])
      session[:referrer_code] = nil
    end
  end

  protected

  def after_sign_up_path_for(resource)
    # '/admin/profile/edit'
    posts_path
  end
end
