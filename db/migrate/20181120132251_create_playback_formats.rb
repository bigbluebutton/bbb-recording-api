class CreatePlaybackFormats < ActiveRecord::Migration[5.2]
  def change
    create_table :playback_formats do |t|
      t.references :recording
      t.string :format
      t.string :url
      t.integer :length
    end
  end
end
