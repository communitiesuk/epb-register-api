# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_06_19_095143) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "address_base", primary_key: "uprn", id: :string, force: :cascade do |t|
    t.string "postcode"
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "address_line4"
    t.string "town"
    t.string "classification_code", limit: 6
    t.string "address_type", limit: 15
    t.string "country_code", limit: 1
    t.index ["address_line1"], name: "index_address_base_on_address_line1"
    t.index ["address_line2"], name: "index_address_base_on_address_line2"
    t.index ["postcode"], name: "index_address_base_on_postcode"
    t.index ["town"], name: "index_address_base_on_town"
  end

  create_table "address_base_versions", primary_key: "version_number", id: :integer, default: nil, force: :cascade do |t|
    t.string "version_name", null: false
    t.datetime "created_at", null: false
    t.index ["version_number"], name: "index_address_base_versions_on_version_number", unique: true
  end

  create_table "assessment_search_address", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.text "address"
  end

  create_table "assessment_statistics", force: :cascade do |t|
    t.integer "assessments_count", null: false
    t.string "assessment_type", null: false
    t.float "rating_average"
    t.datetime "day_date", precision: nil, null: false
    t.integer "transaction_type"
    t.string "country"
    t.index ["assessment_type", "day_date", "transaction_type", "country"], name: "index_assessment_statistics_unique_group", unique: true
    t.index ["assessments_count"], name: "index_assessment_statistics_on_assessments_count"
    t.index ["day_date"], name: "index_assessment_statistics_on_day_date"
    t.index ["rating_average"], name: "index_assessment_statistics_on_rating_average"
  end

  create_table "assessments", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.datetime "date_of_assessment", precision: nil
    t.datetime "date_registered", precision: nil
    t.string "type_of_assessment"
    t.integer "current_energy_efficiency_rating", default: 1, null: false
    t.string "postcode"
    t.datetime "date_of_expiry", precision: nil, null: false
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "address_line4"
    t.string "town"
    t.string "scheme_assessor_id", null: false
    t.boolean "opt_out", default: false
    t.string "address_id"
    t.boolean "migrated", default: false
    t.datetime "cancelled_at", precision: nil
    t.datetime "not_for_issue_at", precision: nil
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.string "hashed_assessment_id"
    t.index "lower((address_line1)::text)", name: "index_assessments_on_address_line1"
    t.index "lower((address_line2)::text)", name: "index_assessments_on_address_line2"
    t.index "lower((address_line3)::text)", name: "index_assessments_on_address_line3"
    t.index "lower((address_line4)::text)", name: "index_assessments_on_address_line4"
    t.index "lower((town)::text)", name: "index_assessments_on_town"
    t.index ["address_id"], name: "index_assessments_on_address_id"
    t.index ["created_at"], name: "index_assessments_on_created_at"
    t.index ["postcode"], name: "index_assessments_on_postcode"
    t.index ["type_of_assessment"], name: "index_assessments_on_type_of_assessment"
  end

  create_table "assessments_address_id", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.string "address_id"
    t.string "source"
    t.index ["address_id"], name: "index_assessments_address_id_on_address_id"
  end

  create_table "assessments_address_id_backup", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.string "address_id"
    t.string "source"
    t.index ["address_id"], name: "index_assessments_address_id_backup_on_address_id"
  end

  create_table "assessments_xml", primary_key: "assessment_id", id: :string, default: "", force: :cascade do |t|
    t.xml "xml"
    t.string "schema_type"
  end

  create_table "assessors", primary_key: "scheme_assessor_id", id: :string, force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "middle_names"
    t.datetime "date_of_birth", precision: nil, null: false
    t.integer "registered_by", limit: 2, null: false
    t.string "telephone_number"
    t.string "email"
    t.string "search_results_comparison_postcode"
    t.string "domestic_rd_sap_qualification"
    t.string "non_domestic_sp3_qualification"
    t.string "non_domestic_cc4_qualification"
    t.string "non_domestic_dec_qualification"
    t.string "non_domestic_nos3_qualification"
    t.string "non_domestic_nos5_qualification"
    t.string "non_domestic_nos4_qualification"
    t.string "domestic_sap_qualification"
    t.string "also_known_as"
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "town"
    t.string "postcode"
    t.string "company_reg_no"
    t.string "company_address_line1"
    t.string "company_address_line2"
    t.string "company_address_line3"
    t.string "company_town"
    t.string "company_postcode"
    t.string "company_website"
    t.string "company_telephone_number"
    t.string "company_email"
    t.string "company_name"
    t.string "gda_qualification"
    t.index ["registered_by"], name: "index_assessors_on_registered_by"
    t.index ["search_results_comparison_postcode"], name: "index_assessors_on_search_results_comparison_postcode"
  end

  create_table "assessors_status_events", force: :cascade do |t|
    t.jsonb "assessor", default: {}
    t.string "scheme_assessor_id"
    t.string "qualification_type"
    t.string "previous_status"
    t.string "new_status"
    t.datetime "recorded_at", precision: nil
    t.string "auth_client_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "event_type", null: false
    t.datetime "timestamp", precision: nil, default: -> { "now()" }, null: false
    t.string "entity_id", null: false
    t.string "entity_type", null: false
    t.jsonb "data"
    t.index ["entity_id"], name: "index_audit_logs_on_entity_id"
    t.index ["event_type"], name: "index_audit_logs_on_event_type"
    t.index ["timestamp"], name: "index_audit_logs_on_timestamp"
  end

  create_table "green_deal_assessments", primary_key: ["green_deal_plan_id", "assessment_id"], force: :cascade do |t|
    t.string "green_deal_plan_id", null: false
    t.string "assessment_id", null: false
    t.index ["green_deal_plan_id", "assessment_id"], name: "index_green_deal_assessments_on_plan_id_and_assessment_id", unique: true
  end

  create_table "green_deal_fuel_code_map", force: :cascade do |t|
    t.integer "fuel_code"
    t.integer "fuel_category"
    t.integer "fuel_heat_source"
  end

  create_table "green_deal_fuel_price_data", force: :cascade do |t|
    t.integer "fuel_heat_source"
    t.decimal "standing_charge", precision: 5, scale: 2
    t.decimal "fuel_price", precision: 10, scale: 2
  end

  create_table "green_deal_plans", primary_key: "green_deal_plan_id", id: :string, force: :cascade do |t|
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.string "provider_name"
    t.string "provider_telephone"
    t.string "provider_email"
    t.decimal "interest_rate"
    t.boolean "fixed_interest_rate"
    t.decimal "charge_uplift_amount"
    t.datetime "charge_uplift_date", precision: nil
    t.boolean "cca_regulated"
    t.boolean "structure_changed"
    t.boolean "measures_removed"
    t.jsonb "measures", default: "[]", null: false
    t.jsonb "charges", default: "[]", null: false
    t.jsonb "savings", default: "[]", null: false
  end

  create_table "linked_assessments", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.string "linked_assessment_id", null: false
    t.index ["linked_assessment_id"], name: "index_linked_assessments_on_linked_assessment_id"
  end

  create_table "open_data_logs", force: :cascade do |t|
    t.string "assessment_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.integer "task_id", null: false
    t.string "report_type"
    t.index ["assessment_id"], name: "index_open_data_logs_on_assessment_id"
    t.index ["task_id"], name: "index_open_data_logs_on_task_id"
  end

  create_table "overridden_lodgement_events", force: :cascade do |t|
    t.string "assessment_id"
    t.jsonb "rule_triggers", default: []
    t.datetime "created_at", null: false
  end

  create_table "postcode_geolocation", force: :cascade do |t|
    t.string "postcode"
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "region"
  end

  create_table "postcode_outcode_geolocations", force: :cascade do |t|
    t.string "outcode"
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "region"
  end

  create_table "schemes", primary_key: "scheme_id", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.index ["name"], name: "index_schemes_on_name", unique: true
  end

  create_table "user_satisfaction", primary_key: "month", id: { type: :datetime, precision: nil }, force: :cascade do |t|
    t.integer "very_satisfied", null: false
    t.integer "satisfied", null: false
    t.integer "neither", null: false
    t.integer "dissatisfied", null: false
    t.integer "very_dissatisfied", null: false
  end

  add_foreign_key "assessments", "assessors", column: "scheme_assessor_id", primary_key: "scheme_assessor_id"
  add_foreign_key "assessments_xml", "assessments", primary_key: "assessment_id"
  add_foreign_key "assessors", "schemes", column: "registered_by", primary_key: "scheme_id"
  add_foreign_key "green_deal_assessments", "assessments", primary_key: "assessment_id", name: "fk_assessment_id_assessments"
  add_foreign_key "green_deal_assessments", "green_deal_plans", primary_key: "green_deal_plan_id", name: "fk_green_deal_plan_id_green_deal_plans", on_delete: :cascade
end
