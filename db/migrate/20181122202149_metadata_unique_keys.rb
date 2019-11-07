class MetadataUniqueKeys < ActiveRecord::Migration[5.2]
  def change
    remove_index :metadata, :recording_id
    add_index :metadata, [:recording_id, :key], unique: true
  end
end
