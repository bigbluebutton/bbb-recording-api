class CreateMetadata < ActiveRecord::Migration[5.2]
  def change
    create_table :metadata do |t|
      t.references :recording
      t.string :key
      t.string :value
    end
  end
end
