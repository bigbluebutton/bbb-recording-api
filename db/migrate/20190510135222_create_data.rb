class CreateData < ActiveRecord::Migration[5.2]
  def change
    create_table :data do |t|
      t.string :record_id
      t.json :raw_data
    end
  end
end
