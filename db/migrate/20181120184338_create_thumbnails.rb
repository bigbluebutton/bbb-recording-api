class CreateThumbnails < ActiveRecord::Migration[5.2]
  def change
    create_table :thumbnails do |t|
      t.references :playback_format
      t.integer :width
      t.integer :height
      t.string :alt
      t.string :url
    end
  end
end
