#!/usr/bin/env ruby

rails_environment_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'environment'))

require rails_environment_path
require "redis"

# hack into #to_hash so we don't lose the attributes in thumbnails
# it's either this or using a more complex library like nokogiri
# see https://stackoverflow.com/questions/19309465/keeping-attributes-when-converting-xml-to-ruby-hash#29431089
module ActiveSupport
  class XMLConverter
    private
    def become_content?(value)
      value['type'] == 'file' || (value['__content__'] && (value.keys.size == 1 && value['__content__'].present?))
    end
  end
end

Rails.logger.info "Starting"

published_path = "/var/bigbluebutton/published"
redis_channel = "bigbluebutton:from-rap"

redis = Redis.new(host: ENV["BBB_REDIS_HOST"], port: ENV["BBB_REDIS_PORT"], db: ENV["BBB_REDIS_DB"])

Dir.glob(File.join(published_path, '**', 'metadata.xml')).each do|path|
  matched = path.match(/([^\/]+)\/([^\/]+)\/metadata.xml$/)
  format = matched[1]
  record_id = matched[2]

  xml = File.open(path)
  metadataxml = Hash.from_xml(xml)
  metadataxml = metadataxml["recording"]
  metadataxml["playback"].deep_transform_keys!{ |key|
    if key == "__content__"
      "link"
    else
      key
    end
  }

  event = {
    header: {
      timestamp: DateTime.now.to_i,
      name: "publish_ended",
      current_time: DateTime.now.to_i,
      version: "0.0.1"
    }, payload: {
      success: true,
      step_time: 0, ##??
      playback: metadataxml["playback"],
      metadata: metadataxml["meta"],
      start_time: metadataxml["start_time"].to_i,
      end_time: metadataxml["end_time"].to_i,
      participants: metadataxml["participants"].to_i,
      raw_size: metadataxml["raw_size"],
      workflow: format,
      external_meeting_id: metadataxml["meta"]["meetingId"],
      record_id: record_id,
      meeting_id: record_id
      # published: metadataxml["published"],
    }
  }

  redis.publish redis_channel, event.to_json
end

Rails.logger.info "Ended"
