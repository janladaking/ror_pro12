class PandaController < ActionController::Base
  skip_before_filter :verify_authenticity_token

  def upload_payload
    @upload_payload ||= JSON.parse(params['payload'])
  end

  def authorize_upload
    if Video.accept_upload?(upload_payload['filename'])
      upload = Panda.post('/videos/upload.json', {
        file_name: upload_payload['filename'],
        file_size: upload_payload['filesize'],
        use_all_profiles: true
      })

      render json: { upload_url: upload['location'] }
    else
      head :unprocessable_entity
    end
  end

  def notifications
    if params['event'] == 'video-encoded'
      video = Video.find_by_panda_video_id(params["video_id"])
      if video
        UpdateVideoState.perform_async(video.id)
      end
    end
    render text: "ok"
  end
end

