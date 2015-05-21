class Admin::ProfilesController < Admin::BaseController
  set_tab :profile
  
  def index
    @profile = current_account.profile
  end

  def show
    @profile = current_account.profile
    @account = current_account
  end

  def new
    @profile = AccountProfile.new
    @profile.account = current_account
  end

  def create
    @profile = AccountProfile.create(profile_params)
    @profile.account = current_account
    @profile.save

    redirect_to account_path(current_account)
  end

  def edit
    @profile = current_account.profile
  end

  def update
    @profile = current_account.profile
    @profile.update_attributes(profile_params)

    @profile.private_fields = profile_params[:private_fields]
    @profile.save

    redirect_to account_path(current_account)
  end

  private

  def profile_params
      params.require(:account_profile).permit(:first_name,:last_name, :avatar, :remove_avatar, :description, :private_fields=>[])
  end

end
