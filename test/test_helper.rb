ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'

module ActiveSupport
  class TestCase
    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def encode_bbb_params(api_method, query_string)
      checksum = ::Digest::SHA1.hexdigest("#{api_method}#{query_string}#{ENV.fetch('BBB_SECRET')}")
      if query_string.blank?
        "checksum=#{checksum}"
      else
        "#{query_string}&checksum=#{checksum}"
      end
    end
  end
end

module RedisStub
  def run
    # Stub the Redis publisher calls, each test case expects maximun 8 calls.
    redis_calls = 8
    mock = MiniTest::Mock.new
    redis_calls.times.each { mock.expect :publish, true, [String, String] }
    ::RedisPublisher.stub :redis, mock do
      super
    end
  end
end

