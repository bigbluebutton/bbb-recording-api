# == Schema Information
#
# Table name: thumbnails
#
#  id                 :integer          not null, primary key
#  playback_format_id :integer
#  width              :integer
#  height             :integer
#  alt                :string
#  url                :string
#  sequence           :integer
#

class Thumbnail < ApplicationRecord
  belongs_to :playback_format
  default_scope { order(sequence: :asc) }
end
