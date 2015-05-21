class AccountProfile < ActiveRecord::Base
  mount_uploader :avatar, AvatarUploader
  serialize :private_fields

  belongs_to :account

  validates :account, presence: true
  validates :account_id, uniqueness: true
  validate :avatar_file_size

  PRIVATABLE_FIELDS = %w( email )
  PRIVATABLE_FIELDS.each do |field_name|
    define_method "#{field_name}_private?" do
      return false if self.private_fields.blank?
      return self.private_fields.include?(field_name)
    end
  end

  def avatar_file_size
    if !avatar.blank?
      if !avatar.file.blank?
        if avatar.file.size.to_f/(1000*1000) > 2
          errors.add(:file, "You cannot upload a file greater than 2MB")
        end
      end
    end
  end

  def profile_image
    return avatar_url unless avatar_url.blank?
    'nouserimage.jpg'
  end
end
