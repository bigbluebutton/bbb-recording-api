class Recording < ApplicationRecord
  has_many :metadata
  has_many :playback_formats

  scope :with_recording_id_prefixes, ->(recording_ids) do
    if recording_ids.length > 0
      rid_prefixes = recording_ids.map do |rid|
        sanitize_sql_like(rid, '|') + '%'
      end
      query_string = Array.new(recording_ids.length,
                               "recording_id LIKE ? ESCAPE '|'")
          .join(' OR ')
      where(query_string, *rid_prefixes)
    end
  end
end
