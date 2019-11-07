class UniqueIndexOnPlaybackFormats < ActiveRecord::Migration[5.2]
  def change
    remove_index :playback_formats, :recording_id
    add_index :playback_formats, %i[recording_id format], unique: true
  end
end
