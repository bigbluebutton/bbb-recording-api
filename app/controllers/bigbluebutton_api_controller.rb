class BigbluebuttonApiController < ApplicationController
  def get_recordings
    query = Recording.includes(:playback_formats, :metadata)
    query = query.with_recording_id_prefixes(params['recordID'].split(',')) if params['recordID'].present?
    query = query.where(meeting_id: params['meetingID'].split(',')) if params['meetingID'].present?

    @recordings = query.all
  end
end
