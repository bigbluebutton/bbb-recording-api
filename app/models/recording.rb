class Recording < ApplicationRecord
  has_many :metadata, dependent: :destroy
  has_many :playback_formats, dependent: :destroy

  scope :with_recording_id_prefixes, lambda { |recording_ids|
    return if recording_ids.empty?

    rid_prefixes = recording_ids.map { |rid| sanitize_sql_like(rid, '|') + '%' }
    query_string = Array.new(recording_ids.length, "record_id LIKE ? ESCAPE '|'").join(' OR ')

    where(query_string, *rid_prefixes)
  }

  def self.sync_from_redis(message)
    header = message["header"]
    payload = message["payload"]
    attrs = {}

    record_id = payload["record_id"]
    recording = Recording.find_or_create_by(record_id: record_id)

    attrs[:meeting_id] = payload["external_meeting_id"]

    case header["name"]
    when /^archive_/, /^sanity_/, "process_started"
      attrs[:state] = 'processing'
    when "process_ended", "publish_started"
      attrs[:state] = 'processing'
    when "publish_ended"
      attrs[:state] = 'published'
      attrs[:starttime] = payload["start_time"]
      attrs[:endtime] = payload["end_time"]
    end

    if payload.has_key?("metadata")
      metadata = payload["metadata"]
      attrs[:name] = metadata["meetingName"]

      metadata.each do |key, value|
        meta = Metadatum.find_or_create_by(recording: recording, key: key)
        meta.update_attributes(value: value)
      end
    end

    if payload.has_key?("playback")
      playbacks = payload["playback"]
      playbacks = [playbacks] unless playbacks.is_a?(Array)

      playbacks.each do |playback|
        format = PlaybackFormat.find_or_create_by(recording: recording, format: playback["format"])
        format.update_attributes(
          url: PlaybackFormat.parse_url(playback["link"]),
          length: playback["duration"],
          processing_time: playback["processing_time"]
        )
      end
    end

    recording.update_attributes(attrs)
  end
end
