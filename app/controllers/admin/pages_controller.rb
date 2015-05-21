class Admin::PagesController < Admin::BaseController

  before_filter :load_page, only: [:show, :update, :edit, :destroy]
  
  set_tab :page

  def index
    @pages = current_account.pages
  end

  def show
  end
  
  def load_page
    @page = current_account.pages.find(params[:id])
  end
  
  private

    def page_params
      params.require(:page).permit(:title,:content,:bootsy_image_gallery_id)
    end
end
