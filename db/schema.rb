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

ActiveRecord::Schema.define(version: 2019_05_10_135222) do

  create_table "data", force: :cascade do |t|
    t.string "record_id"
    t.json "raw_data"
  end

  create_table "metadata", force: :cascade do |t|
    t.integer "recording_id"
    t.string "key"
    t.string "value"
    t.index ["recording_id", "key"], name: "index_metadata_on_recording_id_and_key", unique: true
  end

  create_table "playback_formats", force: :cascade do |t|
    t.integer "recording_id"
    t.string "format"
    t.string "url"
    t.integer "length"
    t.integer "processing_time"
    t.index ["recording_id", "format"], name: "index_playback_formats_on_recording_id_and_format", unique: true
  end

  create_table "recordings", force: :cascade do |t|
    t.string "record_id"
    t.string "meeting_id"
    t.string "name"
    t.boolean "published"
    t.integer "participants"
    t.string "state"
    t.datetime "starttime"
    t.datetime "endtime"
    t.datetime "deleted_at"
    t.index ["meeting_id"], name: "index_recordings_on_meeting_id"
    t.index ["record_id"], name: "index_recordings_on_record_id", unique: true
  end

  create_table "thumbnails", force: :cascade do |t|
    t.integer "playback_format_id"
    t.integer "width"
    t.integer "height"
    t.string "alt"
    t.string "url"
    t.integer "sequence"
    t.index ["playback_format_id"], name: "index_thumbnails_on_playback_format_id"
  end

end
