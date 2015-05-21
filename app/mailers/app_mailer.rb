class AppMailer < ActionMailer::Base
  helper :application
  default from: "noreply@videopage7.com"

  unless Rails.env.test?
    layout 'mail'

    before_filter do
      attachments.inline['logo.png'] = File.read(Rails.root.join('app/assets/images', 'logo.png'))
    end
  end
end
