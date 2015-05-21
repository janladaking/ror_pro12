class AccountMailer < AppMailer
  def payment_success_mail(order_id)
    @order = Order.find(order_id)
    @account = @order.account

    if @order.invoice_file?
      attachments[@order.invoice_filename] = @order.invoice_file.read
    end
    
    mail(subject: "[Videopage7] Your payment has been completed.", to: @account.email)
  end
end
