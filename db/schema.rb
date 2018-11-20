# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_11_20_132251) do

  create_table "metadata", force: :cascade do |t|
    t.integer "recording_id"
    t.string "key"
    t.string "value"
    t.index ["recording_id"], name: "index_metadata_on_recording_id"
  end

  create_table "playback_formats", force: :cascade do |t|
    t.integer "recording_id"
    t.string "format"
    t.string "url"
    t.integer "length"
    t.index ["recording_id"], name: "index_playback_formats_on_recording_id"
  end

  create_table "recordings", force: :cascade do |t|
    t.string "record_id"
    t.string "meeting_id"
    t.string "name"
  end

end
