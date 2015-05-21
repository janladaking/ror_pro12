require 'timeout'
class Post < ActiveRecord::Base
  include AutoHtml
  include Bootsy::Container

  acts_as_commontable
  acts_as_paranoid
  
  #post status: published, draft

  has_one :video
  belongs_to :account
  belongs_to :category

  scope :published, -> { where(published: true) }
  
  validates :title, presence: true
  validates :account_id, presence: true
  validate :validate_video_ability, on: :update
  validates_length_of :content, maximum: 2048
  validates_length_of :excerpt, maximum: 255

  after_save :send_new_post_notification
  before_destroy :set_post_status_to_trash
  before_restore :set_post_status_to_draft

  auto_html_for :video_url do
    html_escape
    image
    youtube(:width => '100%', :height => nil, :autoplay => false)
    vimeo(:width => '100%', :height => nil, :autoplay => false)
    link :target => "_blank", :rel => "nofollow"
    simple_format
  end

  def validate_video_ability
    errors.add(:video_url, 'Please input video url or upload your video.') unless self.has_video?
    if self.has_embeded_video?
      errors.add(:video_url, 'Please input correct youtube or vimeo url.') if embeded_video.blank? or !embeded_video.available?
    end
  end

  def self.search(account, category_id)
    posts = nil
    if account.blank?
      posts = Post.all.published
    else
      posts = account.posts.published
    end
    posts = posts.where(category_id: category_id) if !category_id.blank?
    return posts
  end

  def publish!
    if video.present? && video.screenshot.blank?
      video.refresh
      return false unless screenshot
    end

    self.status = 'published'
    self.published = true
    self.save
  end

  def unpublish!
    self.status = 'draft'
    self.published = false
    self.save
  end

  def save_draft!
    self.status = 'draft'
    self.published = false
    self.save
  end

  def the_excerpt
    return self.excerpt if self.excerpt.present?
    self.content.html_safe.truncate(100)
  end

  def embeded_video
    if has_embeded_video?
      begin
        video = VideoInfo.new(self.video_url)
        return video
      rescue
        return nil
      end
    end

    return nil
  end

  def screenshot
    begin
      return self.embeded_video.thumbnail_large if !self.embeded_video.blank?
      return self.video.screenshot if !self.video.blank?
    rescue
      return nil
    end

    return nil
  end

  def has_video?
    self.video.present? or self.video_url.present?
  end

  def has_panda_video?
    return false if has_video?
    return self.video.panda_video_id.present?
  end

  def has_embeded_video?
    self.video_url.present?
  end

  # send email notification to followers
  def send_new_post_notification
    if self.published_changed?
      self.account.followers.each do |account|
        Notifier.delay.send_new_post_to_follower(self.id, account.id)
      end
    end
  end

  def set_post_status_to_trash
    self.status = 'trash'
    self.save(validate: false)
  end

  def set_post_status_to_draft
    self.status = 'draft'
    self.save(validate: false)
  end

end
