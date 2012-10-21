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

ActiveRecord::Schema.define(:version => 20121006165409) do

  create_table "CompileReport", :primary_key => "CompileReportID", :force => true do |t|
    t.string  "CouchEventID",      :limit => 250
    t.string  "EventName",         :limit => 250
    t.integer "Capacity"
    t.integer "RegCountStart"
    t.integer "RegCountEnd"
    t.integer "RegCountTotal"
    t.integer "FBCountStart"
    t.integer "FBCountEnd"
    t.integer "FBCountTotal"
    t.integer "TwitterCountStart"
    t.integer "TwitterCountEnd"
    t.integer "TwitterCountTotal"
    t.string  "SessionID",         :limit => 250
    t.float   "CapacityPercent"
  end

  create_table "CompileTwitter", :primary_key => "CompileTwitterID", :force => true do |t|
    t.string   "CouchEventID", :limit => 250
    t.string   "TwitterID",    :limit => 250
    t.datetime "PollDate"
    t.datetime "TwitterDate"
  end

  create_table "ErrorLog", :primary_key => "ErrorLogID", :force => true do |t|
    t.string   "Message",    :limit => 2500
    t.string   "StackTrace", :limit => 5000
    t.string   "Module",     :limit => 50
    t.datetime "DateLogged"
  end

  create_table "EventProfile", :primary_key => "EventProfileID", :force => true do |t|
    t.string   "CouchEventID",    :limit => 250, :null => false
    t.datetime "EventDate"
    t.integer  "RoomCapacity"
    t.integer  "IncrementTypeID"
    t.float    "IncrementValue"
    t.datetime "LastUpdate"
    t.boolean  "IsDeleted"
    t.string   "HashTag",         :limit => 250
    t.string   "EventName",       :limit => 250
    t.float    "Ranking"
  end

  create_table "ImportEvent", :primary_key => "Import_EventID", :force => true do |t|
    t.string   "CouchEventID", :limit => 250
    t.datetime "EventDate"
    t.integer  "RoomCapacity"
    t.string   "HashTag",      :limit => 250
    t.string   "EventName",    :limit => 250
  end

  create_table "ImportFacebook", :primary_key => "ImportFacebookID", :force => true do |t|
    t.string   "CouchEventID", :limit => 250, :null => false
    t.integer  "Count"
    t.datetime "PollDate"
  end

  create_table "ImportTwitter", :primary_key => "ImportTwitterID", :force => true do |t|
    t.string   "CouchEventID", :limit => 250
    t.string   "TwitterID",    :limit => 250
    t.datetime "PollDate"
    t.datetime "TwitterDate"
  end

  create_table "ImportUser", :primary_key => "ImportUserID", :force => true do |t|
    t.string   "UserID",       :limit => 100
    t.string   "CouchEventID", :limit => 100
    t.datetime "DateAdded"
    t.datetime "DatePolled"
  end

end
