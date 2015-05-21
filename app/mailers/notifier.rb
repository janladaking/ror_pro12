class Notifier < AppMailer
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::DateHelper

  def send_new_post_to_follower(post_id, follower_id)
    @post = Post.find(post_id)
    @author = @post.account
    @follower = Account.find(follower_id)
    @host = "#{@author.blog_alias}.videopage7.com"
    mail(subject: "[VideoPage7] New post arrived from #{@author.full_name}", to: @follower.email, from: @author.email)
  end
end
