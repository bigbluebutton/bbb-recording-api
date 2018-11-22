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
    query = Recording.includes(playback_formats: [ :thumbnails ], metadata: [])
    query = query.with_recording_id_prefixes(params[:recordID].split(',')) if params[:recordID].present?
    query = query.where(meeting_id: params[:meetingID].split(',')) if params[:meetingID].present?

    @recordings = query.order(starttime: :desc).all
    @url_prefix = "#{request.protocol}#{request.host}"
    render :get_recordings
  end

  def publishRecordings
    raise ApiError.new('missingParamRecordID', 'You must specify a recordID.') if params[:recordID].blank?
    raise ApiError.new('missingParamPublish', 'You must specify a publish value true or false.') if params[:publish].blank?

    publish = params[:publish].casecmp('true').zero?

    query = Recording.where(record_id: params[:recordID].split(','), state: 'published')
    raise ApiError.new('notFound', 'We could not find recordings') if query.none?

    query.where.not(published: publish).update_all(published: publish)

    @published = publish
    render :publish_recordings
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
    our_checksum = Digest::SHA1.hexdigest(action_name + query_string + ENV.fetch('BBB_SECRET'))
    return if our_checksum == params[:checksum]

    raise ApiError.new('checksumError', 'You did not pass the checksum security check')
  end
end
