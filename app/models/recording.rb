require 'redis_publisher'

class Recording < ApplicationRecord
  has_many :metadata, dependent: :destroy
  has_many :playback_formats, dependent: :destroy
  has_one :datum, dependent: :destroy, inverse_of: 'recording', required: false

  validates :state, inclusion: { in: %w[processing processed published unpublished deleted] },
                    allow_nil: true
  validates :record_id, uniqueness: true

  after_save :publish_to_redis_after_save
  after_destroy :publish_to_redis_after_destroy

  scope :with_recording_id_prefixes, lambda { |recording_ids|
    return none if recording_ids.empty?

    rid_prefixes = recording_ids.map { |rid| sanitize_sql_like(rid, '|') + '%' }
    query_string = Array.new(recording_ids.length, "record_id LIKE ? ESCAPE '|'").join(' OR ')

    where(query_string, *rid_prefixes)
  }

  def self.sync_from_redis(message)
    header = message['header']
    payload = message['payload']

    record_id = payload['record_id']
    Recording.transaction do
      recording = Recording.lock.find_or_initialize_by(record_id: record_id)

      recording.meeting_id = payload['external_meeting_id'] if payload.key?('external_meeting_id')

      # TODO: changing the states like this might be wrong if there's more than 1 playback format
      update_recording_by_event_name(header['name'], recording, payload)

      # override attributes if present in the event
      recording.published = payload['published'] if payload.key?('published')
      recording.name = payload['metadata']['meetingName'] if payload.key?('metadata')
      recording.save!

      recording.sync_metadata_from_redis(payload['metadata']) if payload.key?('metadata')
      recording.sync_playbacks_from_redis(payload['playback']) if payload.key?('playback')
      recording
    end
  end

  def self.update_recording_by_event_name(event_name, recording, payload)
    case event_name
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
  end

  def self.metadata_updated(record_ids = [])
    record_ids.each do |record_id|
      rec = Recording.find_by(record_id: record_id)
      rec.publish_metadata_to_redis if rec.present?
    end
  end

  def publish_metadata_to_redis
    RedisPublisher.recording_updated(self)
  end

  def data_file_path
    "/var/bigbluebutton/events/#{record_id}/data.json"
  end

  def sync_metadata_from_redis(meta)
    Metadatum.upsert_by_record_id(record_id, meta)
  end

  def sync_playbacks_from_redis(playbacks)
    playbacks = [playbacks] unless playbacks.is_a?(Array)
    playbacks.each do |playback|
      sync_playback_from_redis(playback)
    end
  end

  def sync_playback_from_redis(playback)
    format = PlaybackFormat.find_or_create_by(recording: self, format: playback['format'])
    format.update(
      url: URI(playback['link'].strip).request_uri,
      length: playback['duration'],
      processing_time: playback['processing_time']
    )

    return unless playback.key?('extensions')

    images = playback['extensions']['preview']['images']['image']
    images = [images] unless images.is_a?(Array)
    save_images(images, format)
  end

  def save_images(images, format)
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
      thumb.update(
        width: image['width'],
        height: image['height'],
        alt: image['alt'],
        sequence: i
      )
    end
  end

  private

  def publish_to_redis_after_save
    if saved_changes.include?('state') && saved_changes['state'][1] == 'deleted'
      RedisPublisher.recording_deleted(self)
    elsif saved_changes.include?('published')
      if published?
        RedisPublisher.recording_published(self)
      else
        RedisPublisher.recording_unpublished(self)
      end
    end
  end

  def publish_to_redis_after_destroy
    RedisPublisher.recording_deleted(self)
  end
end
