#!/usr/bin/env ruby

rails_environment_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'environment'))

require "redis"
require rails_environment_path

Rails.logger.info "Starting"

redis = Redis.new(host: ENV["BBB_REDIS_HOST"], port: ENV["BBB_REDIS_PORT"], db: ENV["BBB_REDIS_DB"])

redis.subscribe("bigbluebutton:from-rap") do |on|
  on.subscribe do |channel, subscriptions|
    Rails.logger.info "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
  end

  on.message do |channel, message|
    Rails.logger.info "Received message from #{channel}: #{message}"
    Recording.sync_from_redis(JSON.parse(message))
  end

  on.unsubscribe do |channel, subscriptions|
    Rails.logger.info "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
  end
end

Rails.logger.info "Ended"
