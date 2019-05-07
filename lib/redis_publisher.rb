require 'redis'

class RedisPublisher

  def initialize
    @redis = Redis.new(
      host: ENV['BBB_REDIS_HOST'],
      port: ENV['BBB_REDIS_PORT'],
      db: ENV['BBB_REDIS_DB'],
      tcp_keepalive: 20
    )
    @channel = ENV['BBB_REDIS_PUBLISH_CHANNEL']
  end

  def published_recording(recording)
    @redis.publish @channel, event('PublishedRecordingSysMsg', recording).to_json
  end

  def unpublished_recording(recording)
    @redis.publish @channel, event('UnpublishedRecordingSysMsg', recording).to_json
  end

  def deleted_recording(recording)
    @redis.publish @channel, event('DeletedRecordingSysMsg', recording).to_json
  end

  private

  def event(name, recording)
    {
      envelope: {
        name: name,
        routing: {
          sender: 'bbb-recording-api'
        }
      },
      core: {
        header: {
          name: name
        },
        body: {
          recordId: recording.record_id
        }
      }
    }
  end
end
