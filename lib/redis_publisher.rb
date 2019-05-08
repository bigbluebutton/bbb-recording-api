class RedisPublisher
  def self.recording_published(recording)
    redis.publish channel, make_event('PublishedRecordingSysMsg', recording).to_json
  end

  def self.recording_unpublished(recording)
    redis.publish channel, make_event('UnpublishedRecordingSysMsg', recording).to_json
  end

  def self.recording_deleted(recording)
    redis.publish channel, make_event('DeletedRecordingSysMsg', recording).to_json
  end

  def self.recording_updated(recording)
    redis.publish channel, make_event('UpdatedRecordingSysMsg', recording, true).to_json
  end

  def self.redis
    Rails.application.config.redis
  end

  def self.channel
    ENV['BBB_REDIS_PUBLISH_CHANNEL']
  end

  def self.make_event(name, recording, meta = false)
    e = {
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
    e[:core][:body][:metadata] = recording.metadata if meta
    e
  end
end
