# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140424052505) do

  create_table "devices", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "slideshow_id"
    t.string   "password"
    t.string   "deviceid",     :limit => 20
    t.integer  "location_id"
  end

  add_index "devices", ["deviceid"], :name => "index_devices_on_deviceid"
  add_index "devices", ["name"], :name => "index_devices_on_name"

  create_table "locations", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "locations", ["name"], :name => "index_locations_on_name", :unique => true

  create_table "slides", :force => true do |t|
    t.string   "name"
    t.text     "url"
    t.integer  "display_time"
    t.string   "transition",   :limit => 16, :default => "none", :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.string   "media_type",   :limit => 16, :default => "none", :null => false
    t.text     "feed_path"
    t.integer  "scrub_time"
    t.integer  "stop_time"
  end

  create_table "slideshow_slides", :force => true do |t|
    t.integer "slideshow_id", :null => false
    t.integer "slide_id",     :null => false
  end

  create_table "slideshows", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
