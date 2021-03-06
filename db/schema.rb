# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090820204557) do

  create_table "filelists", :force => true do |t|
    t.string   "path"
    t.integer  "version"
    t.string   "repo"
    t.string   "record_type"
    t.string   "author"
    t.boolean  "current"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
  end

  add_index "filelists", ["repo", "record_type"], :name => "file_repo_type_indx"

  create_table "images", :force => true do |t|
    t.integer  "parent_id"
    t.string   "content_type"
    t.string   "filename"
    t.string   "thumbnail"
    t.integer  "size"
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "images", ["parent_id"], :name => "image_parent_indx"

  create_table "lessons", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "role",                                    :default => "student"
  end

  create_table "wordlocs", :force => true do |t|
    t.integer  "file_id"
    t.integer  "word_id"
    t.integer  "location"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "wordlocs", ["word_id"], :name => "word_file_indx"

  create_table "words", :force => true do |t|
    t.string   "word"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "words", ["word"], :name => "word_indx"

end
