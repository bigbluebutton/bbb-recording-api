class BigbluebuttonApiController < ApplicationController
  class ApiError < StandardError
    attr_reader :key

    def initialize(key, message)
      super(message)
      @key = key
    end
  end

  before_action :checksum
  rescue_from ApiError, with: :api_error

  def getRecordings
    query = Recording.includes(:playback_formats, :metadata)
    query = query.with_recording_id_prefixes(params[:recordID].split(',')) if params[:recordID].present?
    query = query.where(meeting_id: params[:meetingID].split(',')) if params[:meetingID].present?

    @recordings = query.all
    render :get_recordings
  end

  private

  def api_error(exception)
    @exception = exception
    render :api_error
  end

  def checksum
    raise ApiError.new('checksumError', 'You did not pass the checksum security check') if params[:checksum].blank?

    query_string = request.query_string.gsub(/^checksum=#{params[:checksum]}&?/, '')
    query_string = query_string.gsub(/&?checksum=#{params[:checksum]}/, '')
    our_checksum = Digest::SHA1.hexdigest(action_name + query_string + ENV.fetch('BIGBLUEBUTTON_SECRET'))
    return if our_checksum == params[:checksum]

    raise ApiError.new('checksumError', 'You did not pass the checksum security check')
  end
end
