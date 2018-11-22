class UniqueIndexRecordingId < ActiveRecord::Migration[5.2]
  def change
    remove_index :recordings, :record_id
    add_index :recordings, :record_id, unique: true
  end
end
