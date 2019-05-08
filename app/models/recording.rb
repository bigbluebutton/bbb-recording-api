require 'redis_publisher'

class Recording < ApplicationRecord
  has_many :metadata, dependent: :destroy
  has_many :playback_formats, dependent: :destroy

  validates :state, inclusion: { in: %w[processing processed published unpublished deleted] }, allow_nil: true

  after_save :publish_to_redis_after_save
  after_destroy :publish_to_redis_after_destroy

  scope :with_recording_id_prefixes, lambda { |recording_ids|
    return none if recording_ids.empty?

    rid_prefixes = recording_ids.map { |rid| sanitize_sql_like(rid, '|') + '%' }
    query_string = Array.new(recording_ids.length, "record_id LIKE ? ESCAPE '|'").join(' OR ')

    where(query_string, *rid_prefixes)
  }

  def self.sync_from_redis(message)
    header = message["header"]
    payload = message["payload"]

    record_id = payload['record_id']
    Recording.transaction do
      recording = Recording.lock.find_or_initialize_by(record_id: record_id)

      recording.meeting_id = payload['external_meeting_id'] if payload.key?('external_meeting_id')

      case header['name']
      when /^archive_/, /^sanity_/, 'process_started'
        recording.state = 'processing'
        recording.published = false
      when 'process_ended', 'publish_started'
        recording.state = 'processed'
        recording.published = false
      when 'publish_ended'
        recording.state = 'published'
        recording.starttime = Time.at(Rational(payload['start_time'], 1000)).utc
        recording.endtime = Time.at(Rational(payload['end_time'], 1000)).utc
        recording.participants = payload['participants']
        recording.published = true
      end

      # override attributes if present in the event
      recording.published = payload['published'] if payload.key?('published')
      recording.name = payload['metadata']['meetingName'] if payload.key?('metadata')
      recording.save!

      Metadatum.upsert_by_record_id(payload['record_id'], payload['metadata']) if payload.key?('metadata')

      if payload.key?("playback")
        playbacks = payload["playback"]
        playbacks = [playbacks] unless playbacks.is_a?(Array)

        playbacks.each do |playback|
          format = PlaybackFormat.find_or_create_by(recording: recording, format: playback["format"])
          format.update(
            url: URI(playback["link"]).request_uri,
            length: playback["duration"],
            processing_time: playback["processing_time"]
          )

          if playback.has_key?("extensions")
            images = playback["extensions"]["preview"]["images"]["image"]
            images = [images] unless images.is_a?(Array)

            images.each_with_index do |image, i|
              # newer versions of bbb have a different format
              # old: {"images"=>{"image"=>["https://....png"]}}
              # new: {"images"=>{"image"=>[{"width"=>"176", "height"=>"136", "alt"=>"", "link"=>"https://....png"}]}}
              image = { 'link' => image } if image.is_a?(String)

              begin
                url = URI(image['link'].strip).request_uri
              rescue URI::InvalidURIError
                Rails.logger.warn("Invalid URL '#{image['link'].strip}'")
              end
              thumb = Thumbnail.find_or_create_by(
                playback_format: format,
                url: url
              )
              thumb.update_attributes(
                width: image["width"],
                height: image["height"],
                alt: image["alt"],
                sequence: i
              )
            end
          end
        end
      end
    end
  end

  def self.metadata_updated(record_ids = [])
    record_ids.each do |record_id|
      rec = Recording.find_by(record_id: record_id)
      rec.publish_metadata_to_redis if rec.present?
    end
  end

  def publish_metadata_to_redis
    RedisPublisher.new.recording_updated(self)
  end

  private

  def publish_to_redis_after_save
    publisher = RedisPublisher.new
    if saved_changes.include?('state') && saved_changes['state'][1] == 'deleted'
      publisher.recording_deleted(self)
    elsif saved_changes.include?('published')
      if published?
        publisher.recording_published(self)
      else
        publisher.recording_unpublished(self)
      end
    end
  end

  def publish_to_redis_after_destroy
    RedisPublisher.new.recording_deleted(self)
  end
end
