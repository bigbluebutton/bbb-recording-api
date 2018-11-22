class AddSequenceToThumbnails < ActiveRecord::Migration[5.2]
  def change
    change_table :thumbnails do |t|
      t.integer :sequence
    end
  end
end
