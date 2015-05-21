class Admin::PostsController < Admin::BaseController

  before_filter :load_post, only: [:show, :update, :destroy, :edit, :publish, :unpublish]

  before_filter only: [:new, :create] do
    unless current_account.can_create_post?
      redirect_to admin_posts_path, notice: 'Upgrade your plan to post more videos'
      false
    end
  end
  
  set_tab :post

  def index
    status = params[:status]
    status ||= 'all'
    set_tab status.to_sym
    @posts = current_account.posts_for(status)
    @posts = @posts.order("created_at desc").page(params[:page]).per(12)
  end

  def new
    @post = Post.new
    @post.account = current_account
  end

  def show
  end

  def edit
    @post.valid?
  end

  def update
    if @post.update_attributes(post_params)
      flash.now[:success] = "Updated successfully."
    end
    render :edit
  end

  def create
    @post = Post.new(post_params)
    @post.account = current_account
    if @post.save_draft!

      if @post.has_embeded_video?
        flash.now[:success] = "Created successfully"
        render :edit
      else
        flash[:success] = "Created successfully, Please upload your video!"
        redirect_to new_admin_post_video_path(@post) 
      end

    else
      render :edit
    end
  end

  def destroy
    if @post.destroy()
      flash[:success] = "Deleted successfully"
    else
      flash[:success] = "Cannot delete."
    end
    redirect_to admin_posts_path
  end

  def really_destroy
    @post = current_account.posts.with_deleted.find(params[:id])
    @post.really_destroy!
    redirect_to admin_posts_path
  end

  def restore
    @post = current_account.posts.with_deleted.find(params[:id])
    @post.restore
    flash[:success] = "Restored successfully"
    redirect_to admin_posts_path(status: 'trash')
  end

  def publish
    if @post.publish!
      flash[:success] = "Published successfully."
      redirect_to admin_posts_path
    else
      flash[:alert] = "Can't publish unfinished video"
      redirect_to edit_admin_post_path(@post)
    end
  end

  def unpublish
    if @post.unpublish!
      flash[:success] = "Unpublished successfully."
      redirect_to admin_posts_path
    else
      redirect_to edit_admin_post_path(@post)
    end
  end

  private

    def load_post
      @post = current_account.posts.find(params[:id]) unless params[:id].blank?
    end
    
    def post_params
      attrs = [:title, :content, :excerpt, :video_url, :bootsy_image_gallery_id]

      if current_account.can_use_post_category?
        attrs << :category_id
      end

      params.require(:post).permit(*attrs)
    end
end
