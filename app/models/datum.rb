# == Schema Information
#
# Table name: data
#
#  id        :integer          not null, primary key
#  record_id :string
#  raw_data  :json
#

class Datum < ApplicationRecord
  # we do this through :record_id so we can parse data independently from recordings
  # data might have a recording or might not
  belongs_to :recording, foreign_key: 'record_id', primary_key: 'record_id',
                         inverse_of: 'datum', required: false

  validates :record_id, uniqueness: true

  def self.sync_from_redis(message)
    header = message['header']
    payload = message['payload']
    record_id = payload['record_id']

    return unless header['name'] == 'data_published'

    datum = Datum.lock.find_or_initialize_by(record_id: record_id)
    datum.raw_data = payload['data']
    datum.save!
  end
end
