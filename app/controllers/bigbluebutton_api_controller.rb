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
    query = Recording.includes(playback_formats: [:thumbnails], metadata: [])
    if params[:recordID].present?
      query = query.with_recording_id_prefixes(params[:recordID].split(','))
    elsif params[:meetingID].present?
      query = query.where(meeting_id: params[:meetingID].split(','))
    end

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

  def updateRecordings
    raise ApiError.new('missingParamRecordID', 'You must specify a recordID.') if params[:recordID].blank?

    record_ids = params[:recordID].split(',')

    add_metadata = {}
    remove_metadata = []
    params.each do |key, value|
      next unless key.start_with?('meta_')

      key = key[5..-1]

      if value.blank?
        remove_metadata << key
      else
        add_metadata[key] = value
      end
    end

    Metadatum.transaction do
      Metadatum.upsert_by_record_id(record_ids, add_metadata)
      Metadatum.delete_by_record_id(record_ids, remove_metadata)
    end

    @updated = !(add_metadata.empty? && remove_metadata.empty?)
    render :update_recordings
  end

  def deleteRecordings
    raise ApiError.new('missingParamRecordID', 'You must specify a recordID.') if params[:recordID].blank?

    query = Recording.where(record_id: params[:recordID].split(','))
    raise ApiError.new('notFound', 'We could not find recordings') if query.none?

    destroyed_recordings = query.destroy_all

    @deleted = !destroyed_recordings.empty?
    render :delete_recordings
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
