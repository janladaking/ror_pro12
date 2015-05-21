class UpdateVideoState
  include Sidekiq::Worker
  sidekiq_options :retry => 5

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(id)
    video = Video.find(id)
    if video.panda_video.status == 'fail'
      # video failed to be uploaded to your bucket
      # Logs go here to show this Issue
    else
      
      video.panda_video.encodings.each do |encoding|
        if encoding.status == "success"
          video.create_video_encoding(encoding)
        else
          Sidekiq.logger.warn "Failed to encode: #{msg['error_message']}"
        end
      end

    end
  end
end

