# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_12_12_150246) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'assessors',
               primary_key: 'scheme_assessor_id',
               id: :string,
               force: :cascade do |t|
    t.string 'first_name'
    t.string 'last_name'
    t.string 'middle_names'
    t.datetime 'date_of_birth'
    t.bigint 'registered_by'
    t.string 'telephone_number'
    t.string 'email'
    t.index %w[registered_by], name: 'index_assessors_on_registered_by'
  end

  create_table 'schemes', primary_key: 'scheme_id', force: :cascade do |t|
    t.string 'name'
    t.index %w[name], name: 'index_schemes_on_name', unique: true
  end

  add_foreign_key 'assessors',
                  'schemes',
                  column: 'registered_by', primary_key: 'scheme_id'
end
