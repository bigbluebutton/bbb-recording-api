class BigbluebuttonApiController < ApplicationController
  def get_recordings
    query = Recording.includes(:playback_formats, :metadata)
    if params['recordID'].present?
      query = query.with_recording_id_prefixes(params['recordID'].split(','))
    elsif params['meetingID'].present?
      query = query.where(meeting_id: params['meetingID'].split(','))
    end

    @recordings = query.all
  end
end
