class Recording < ApplicationRecord
  has_many :metadata, dependent: :destroy
  has_many :playback_formats, dependent: :destroy

  scope :with_recording_id_prefixes, lambda { |recording_ids|
    return none if recording_ids.empty?

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

    attrs[:meeting_id] = payload["external_meeting_id"] if payload.has_key?("external_meeting_id")

    case header["name"]
    when /^archive_/, /^sanity_/, "process_started"
      attrs[:state] = 'processing'
      attrs[:published] = false
    when "process_ended", "publish_started"
      attrs[:state] = 'processed'
      attrs[:published] = false
    when "publish_ended"
      attrs[:state] = 'published'
      attrs[:starttime] = Time.at(payload["start_time"]/1000)
      attrs[:endtime] = Time.at(payload["end_time"]/1000)
      attrs[:participants] = payload["participants"]
      attrs[:published] = true
      # attrs[:raw_size] = payload["raw_size"]
    end

    # override :published in case it's present in the event
    if payload.has_key?("published")
      attrs[:published] = payload["published"]
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
          url: URI(playback["link"]).request_uri,
          length: playback["duration"],
          processing_time: playback["processing_time"]
        )

        if playback.has_key?("extensions")
          images = playback["extensions"]["preview"]["images"]
          images = [images] unless images.is_a?(Array)

          images.each_with_index do |image, i|
            # newer versions of bbb have a different format
            # old: {"images"=>{"image"=>"https://....png"}}
            # new: {"images"=>{"image"=>{"width"=>"176", "height"=>"136", "alt"=>"", "link"=>"https://....png"}}}
            if image["image"].is_a?(Hash)
              image = image["image"]
              image["image"] = image["link"]
            end

            thumb = Thumbnail.find_or_create_by(
              playback_format: format,
              url: URI(image["image"]).request_uri
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

    recording.update_attributes(attrs)
  end
end
