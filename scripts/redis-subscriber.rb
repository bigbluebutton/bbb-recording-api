#!/usr/bin/env ruby

rails_environment_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'environment'))

require "redis"
require rails_environment_path

Rails.logger.info "Starting"

target_events = [
  "archive_started",
  "archive_ended",
  "sanity_started",
  "sanity_ended",
  "process_started",
  "process_ended",
  "publish_started",
  "publish_ended"
]
redis_channel = "bigbluebutton:from-rap"

redis = Redis.new(host: ENV["BBB_REDIS_HOST"], port: ENV["BBB_REDIS_PORT"], db: ENV["BBB_REDIS_DB"])

redis.subscribe(redis_channel) do |on|
  on.subscribe do |channel, subscriptions|
    Rails.logger.info "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
  end

  on.message do |channel, message|
    Rails.logger.info "Received message from #{channel}: #{message}"
    parsed_message = JSON.parse(message)
    name = parsed_message["header"]["name"]
    Recording.sync_from_redis(parsed_message) if target_events.include?(name)
  end

  on.unsubscribe do |channel, subscriptions|
    Rails.logger.info "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
  end
end

Rails.logger.info "Ended"
