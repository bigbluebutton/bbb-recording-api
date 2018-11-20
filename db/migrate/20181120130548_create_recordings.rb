class CreateRecordings < ActiveRecord::Migration[5.2]
  def change
    create_table :recordings do |t|
      t.string :record_id
      t.string :meeting_id
      t.string :name
    end
  end
end
