# == Schema Information
#
# Table name: playback_formats
#
#  id              :integer          not null, primary key
#  recording_id    :integer
#  format          :string
#  url             :string
#  length          :integer
#  processing_time :integer
#

class PlaybackFormat < ApplicationRecord
  belongs_to :recording
  has_many :thumbnails, dependent: :destroy
  default_scope { order(format: :asc) }
end
