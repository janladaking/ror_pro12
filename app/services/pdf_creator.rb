class PdfCreator

  def self.render_invoice(order)
    content = ApplicationController.new.render_to_string(
      template: "admin/orders/invoice.pdf.haml",
      layout: "layouts/pdf.html.haml",
      locals: {
        billing_address: order.billing_address,
        order:           order,
        account:         order.account,
        plan:            order.plan
      }
    )
    # Rails.logger.debug { content }

    WickedPdf.new.pdf_from_string(content)
  end

end
