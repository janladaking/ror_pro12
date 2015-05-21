class VideoEncoding < ActiveRecord::Base
  belongs_to :video

  validates_presence_of :profile_name
  validates_uniqueness_of :profile_name, :scope => [:video_id]

  def self.create_from_panda_encoding(encoding)
    self.create(
      panda_video_id: encoding.video_id,
      profile_name: encoding.profile_name,
      status: encoding.status,
      width: encoding.width,
      height: encoding.height,
      url: encoding.url,
      file_size: encoding.file_size,
      mime_type: encoding.mime_type
      )
  end
end