class PlaybackFormat < ApplicationRecord
  belongs_to :recording
  has_many :thumbnails, dependent: :destroy
end
