class Recording < ApplicationRecord
  has_many :metadatum
  has_many :playback_formats
end
