class PostsController < ApplicationController
  skip_before_action :authenticate_account!, only: [:index, :show]

  before_filter :load_post, only: [:show, :edit]
  
  
  def index
    account = current_author if current_author!=current_account
    @posts = Post.search(account, params[:category_id]).order("created_at desc").page(params[:page]).per(12)
  end

  def show
    # Show the comments without clicking first on "Show Comments"
    @commontator_thread_show = true

    unless @post.video.blank?
      @post.video.refresh unless @post.video.encoded?
    end

    if @post.video_url.present? || (@post.video.present? && @post.video.encoded?)
      @post.increment! :views_count
    end
  end

  private

    def load_post
      @post = Post.find(params[:id])
    end

    def post_params
      params.require(:post).permit(:title,:content, :excerpt, :video_id)
    end

    def restrict_access_on_www
      if request.subdomain.present? && request.subdomain == "www"
        redirect_to impress_pages_path
      end
    end


end
