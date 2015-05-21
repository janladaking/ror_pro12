module TokenGenerator
  extend ActiveSupport::Concern
  
  included do
    before_create :set_token
  end

  def set_token
    unless token
      begin
        self.token = SecureRandom.urlsafe_base64
      end while self.class.exists?(token: token)
    end
  end
end
