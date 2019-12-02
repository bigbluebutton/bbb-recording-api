require 'redis'

Rails.application.config.redis = Redis.new(
  host: ENV['BBB_REDIS_HOST'],
  port: ENV['BBB_REDIS_PORT'],
  db: ENV['BBB_REDIS_DB'],
  tcp_keepalive: 20
)
