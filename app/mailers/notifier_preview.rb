# http://localhost:3000/rails/mailers
class NotifierPreview < ActionMailer::Preview
  def send_new_post_to_follower
    Notifier.send_new_post_to_follower(Post.first.id, Account.first.id)
  end

  def payment_success_mail
    AccountMailer.payment_success_mail(Order.first.id)
  end
end
