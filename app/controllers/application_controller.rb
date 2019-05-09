class ApplicationController < ActionController::API
  include ActionView::Layouts

  class ApiError < StandardError
    attr_reader :key

    def initialize(key, message)
      super(message)
      @key = key
    end
  end

  before_action :checksum
  before_action :set_url_prefix
  rescue_from ApiError, with: :api_error

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

  def parse_metadata
    @metadata = {}
    params.each do |key, value|
      next unless key.start_with?('meta_')

      key = key[5..-1]
      @metadata[key] = value
    end
  end

  def set_url_prefix
    @url_prefix = "#{request.protocol}#{request.host}"
  end
end
