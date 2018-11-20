class AddMoreRecordingProperties < ActiveRecord::Migration[5.2]
  def change
    change_table :recordings do |t|
      t.boolean :published
      t.integer :participants
      t.string :state
      t.timestamp :starttime
      t.timestamp :endtime
      t.index :record_id
      t.index :meeting_id
    end
    change_table :playback_formats do |t|
      t.integer :processing_time
    end
  end
end
