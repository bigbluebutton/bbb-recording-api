class PlaybackFormat < ApplicationRecord
  belongs_to :recording

  def self.parse_url(value)
    if value.present?
      u = URI(value)
      value.gsub(/^#{u.scheme}:\/\/#{u.host}/, '')
    end
  end
end
