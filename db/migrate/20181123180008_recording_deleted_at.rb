class RecordingDeletedAt < ActiveRecord::Migration[5.2]
  def change
    change_table :recordings do |t|
      t.timestamp :deleted_at
    end
  end
end
