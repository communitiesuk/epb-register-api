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

ActiveRecord::Schema[8.1].define(version: 2026_01_15_152511) do
  create_schema "scotland"

  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "fuzzystrmatch"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "public.address_base", primary_key: "uprn", id: :string, force: :cascade do |t|
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "address_line4"
    t.string "address_type", limit: 15
    t.string "classification_code", limit: 6
    t.string "country_code", limit: 1
    t.string "postcode"
    t.string "town"
    t.index ["address_line1"], name: "index_address_base_on_address_line1"
    t.index ["address_line2"], name: "index_address_base_on_address_line2"
    t.index ["postcode"], name: "index_address_base_on_postcode"
    t.index ["town"], name: "index_address_base_on_town"
  end

  create_table "public.address_base_versions", primary_key: "version_number", id: :integer, default: nil, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "version_name", null: false
    t.index ["version_number"], name: "index_address_base_versions_on_version_number", unique: true
  end

  create_table "public.assessment_search_address", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.text "address"
    t.index ["address"], name: "index_address_on_assessment_search_address_trigram", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "public.assessment_statistics", force: :cascade do |t|
    t.string "assessment_type", null: false
    t.integer "assessments_count", null: false
    t.string "country"
    t.datetime "day_date", precision: nil, null: false
    t.float "rating_average"
    t.integer "transaction_type"
    t.index ["assessment_type", "day_date", "transaction_type", "country"], name: "index_assessment_statistics_unique_group", unique: true
    t.index ["assessments_count"], name: "index_assessment_statistics_on_assessments_count"
    t.index ["day_date"], name: "index_assessment_statistics_on_day_date"
    t.index ["rating_average"], name: "index_assessment_statistics_on_rating_average"
  end

  create_table "public.assessments", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.string "address_id"
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "address_line4"
    t.datetime "cancelled_at", precision: nil
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.integer "current_energy_efficiency_rating", default: 1, null: false
    t.datetime "date_of_assessment", precision: nil
    t.datetime "date_of_expiry", precision: nil, null: false
    t.datetime "date_registered", precision: nil
    t.string "hashed_assessment_id"
    t.boolean "migrated", default: false
    t.datetime "not_for_issue_at", precision: nil
    t.boolean "opt_out", default: false
    t.string "postcode"
    t.string "scheme_assessor_id", null: false
    t.string "town"
    t.string "type_of_assessment"
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

  create_table "public.assessments_address_id", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.string "address_id"
    t.datetime "address_updated_at"
    t.float "matched_confidence"
    t.string "matched_uprn", limit: 20
    t.string "source"
    t.index ["address_id"], name: "index_assessments_address_id_on_address_id"
  end

  create_table "public.assessments_country_ids", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.integer "country_id"
    t.index ["country_id"], name: "index_assessments_country_ids_on_country_id"
  end

  create_table "public.assessments_xml", primary_key: "assessment_id", id: :string, default: "", force: :cascade do |t|
    t.string "schema_type"
    t.xml "xml"
  end

  create_table "public.assessors", primary_key: "scheme_assessor_id", id: :string, force: :cascade do |t|
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "also_known_as"
    t.string "company_address_line1"
    t.string "company_address_line2"
    t.string "company_address_line3"
    t.string "company_email"
    t.string "company_name"
    t.string "company_postcode"
    t.string "company_reg_no"
    t.string "company_telephone_number"
    t.string "company_town"
    t.string "company_website"
    t.datetime "date_of_birth", precision: nil, null: false
    t.string "domestic_rd_sap_qualification"
    t.string "domestic_sap_qualification"
    t.string "email"
    t.string "first_name", null: false
    t.string "gda_qualification"
    t.string "last_name", null: false
    t.string "middle_names"
    t.string "non_domestic_cc4_qualification"
    t.string "non_domestic_dec_qualification"
    t.string "non_domestic_nos3_qualification"
    t.string "non_domestic_nos4_qualification"
    t.string "non_domestic_nos5_qualification"
    t.string "non_domestic_sp3_qualification"
    t.string "postcode"
    t.integer "registered_by", limit: 2, null: false
    t.string "search_results_comparison_postcode"
    t.string "telephone_number"
    t.string "town"
    t.index ["registered_by"], name: "index_assessors_on_registered_by"
    t.index ["search_results_comparison_postcode"], name: "index_assessors_on_search_results_comparison_postcode"
  end

  create_table "public.assessors_status_events", force: :cascade do |t|
    t.jsonb "assessor", default: {}
    t.string "auth_client_id"
    t.string "new_status"
    t.string "previous_status"
    t.string "qualification_type"
    t.datetime "recorded_at", precision: nil
    t.string "scheme_assessor_id"
  end

  create_table "public.audit_logs", force: :cascade do |t|
    t.jsonb "data"
    t.string "entity_id", null: false
    t.string "entity_type", null: false
    t.string "event_type", null: false
    t.datetime "timestamp", precision: nil, default: -> { "now()" }, null: false
    t.index ["entity_id"], name: "index_audit_logs_on_entity_id"
    t.index ["event_type"], name: "index_audit_logs_on_event_type"
    t.index ["timestamp"], name: "index_audit_logs_on_timestamp"
  end

  create_table "public.countries", primary_key: "country_id", force: :cascade do |t|
    t.jsonb "address_base_country_code", default: "{}"
    t.string "country_code"
    t.string "country_name"
  end

  create_table "public.green_deal_assessments", primary_key: ["green_deal_plan_id", "assessment_id"], force: :cascade do |t|
    t.string "assessment_id", null: false
    t.string "green_deal_plan_id", null: false
    t.index ["green_deal_plan_id", "assessment_id"], name: "index_green_deal_assessments_on_plan_id_and_assessment_id", unique: true
  end

  create_table "public.green_deal_fuel_code_map", force: :cascade do |t|
    t.integer "fuel_category"
    t.integer "fuel_code"
    t.integer "fuel_heat_source"
  end

  create_table "public.green_deal_fuel_price_data", force: :cascade do |t|
    t.integer "fuel_heat_source"
    t.decimal "fuel_price", precision: 10, scale: 2
    t.decimal "standing_charge", precision: 5, scale: 2
  end

  create_table "public.green_deal_plans", primary_key: "green_deal_plan_id", id: :string, force: :cascade do |t|
    t.boolean "cca_regulated"
    t.decimal "charge_uplift_amount"
    t.datetime "charge_uplift_date", precision: nil
    t.jsonb "charges", default: "[]", null: false
    t.datetime "end_date", precision: nil
    t.boolean "fixed_interest_rate"
    t.decimal "interest_rate"
    t.jsonb "measures", default: "[]", null: false
    t.boolean "measures_removed"
    t.string "provider_email"
    t.string "provider_name"
    t.string "provider_telephone"
    t.jsonb "savings", default: "[]", null: false
    t.datetime "start_date", precision: nil
    t.boolean "structure_changed"
  end

  create_table "public.linked_assessments", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.string "linked_assessment_id", null: false
    t.index ["linked_assessment_id"], name: "index_linked_assessments_on_linked_assessment_id"
  end

  create_table "public.open_data_logs", force: :cascade do |t|
    t.string "assessment_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "report_type"
    t.integer "task_id", null: false
    t.index ["assessment_id"], name: "index_open_data_logs_on_assessment_id"
    t.index ["task_id"], name: "index_open_data_logs_on_task_id"
  end

  create_table "public.overridden_lodgement_events", force: :cascade do |t|
    t.string "assessment_id"
    t.datetime "created_at", null: false
    t.jsonb "rule_triggers", default: []
  end

  create_table "public.postcode_geolocation", force: :cascade do |t|
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "postcode"
    t.string "region"
  end

  create_table "public.postcode_outcode_geolocations", force: :cascade do |t|
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "outcode"
    t.string "region"
  end

  create_table "public.schemes", primary_key: "scheme_id", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "name"
    t.index ["name"], name: "index_schemes_on_name", unique: true
  end

  add_foreign_key "public.assessments", "public.assessors", column: "scheme_assessor_id", primary_key: "scheme_assessor_id"
  add_foreign_key "public.assessments_country_ids", "public.countries", primary_key: "country_id", name: "fks_assessments_country_ids_countries"
  add_foreign_key "public.assessments_xml", "public.assessments", primary_key: "assessment_id"
  add_foreign_key "public.assessors", "public.schemes", column: "registered_by", primary_key: "scheme_id"
  add_foreign_key "public.green_deal_assessments", "public.assessments", primary_key: "assessment_id", name: "fk_assessment_id_assessments"
  add_foreign_key "public.green_deal_assessments", "public.green_deal_plans", primary_key: "green_deal_plan_id", name: "fk_green_deal_plan_id_green_deal_plans", on_delete: :cascade

  create_table "scotland.assessment_search_address", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.text "address"
    t.index ["address"], name: "assessment_search_address_address_idx", using: :gin
  end

  create_table "scotland.assessments", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.string "address_id"
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "address_line4"
    t.datetime "cancelled_at", precision: nil
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.integer "current_energy_efficiency_rating", default: 1, null: false
    t.datetime "date_of_assessment", precision: nil
    t.datetime "date_of_expiry", precision: nil, null: false
    t.datetime "date_registered", precision: nil
    t.string "hashed_assessment_id"
    t.boolean "migrated", default: false
    t.datetime "not_for_issue_at", precision: nil
    t.boolean "opt_out", default: false
    t.string "postcode"
    t.string "scheme_assessor_id", null: false
    t.string "town"
    t.string "type_of_assessment"
    t.index "lower((address_line1)::text)", name: "assessments_lower_idx"
    t.index "lower((address_line2)::text)", name: "assessments_lower_idx1"
    t.index "lower((address_line3)::text)", name: "assessments_lower_idx2"
    t.index "lower((address_line4)::text)", name: "assessments_lower_idx3"
    t.index "lower((town)::text)", name: "assessments_lower_idx4"
    t.index ["address_id"], name: "assessments_address_id_idx"
    t.index ["created_at"], name: "assessments_created_at_idx"
    t.index ["postcode"], name: "assessments_postcode_idx"
    t.index ["type_of_assessment"], name: "assessments_type_of_assessment_idx"
  end

  create_table "scotland.assessments_address_id", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.string "address_id"
    t.datetime "address_updated_at"
    t.float "matched_confidence"
    t.string "matched_uprn", limit: 20
    t.string "source"
    t.index ["address_id"], name: "assessments_address_id_address_id_idx"
  end

  create_table "scotland.assessments_country_ids", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.integer "country_id"
    t.index ["country_id"], name: "assessments_country_ids_country_id_idx"
  end

  create_table "scotland.assessments_xml", primary_key: "assessment_id", id: :string, default: "", force: :cascade do |t|
    t.string "schema_type"
    t.xml "xml"
  end

  create_table "scotland.green_deal_assessments", primary_key: ["green_deal_plan_id", "assessment_id"], force: :cascade do |t|
    t.string "assessment_id", null: false
    t.string "green_deal_plan_id", null: false
    t.index ["green_deal_plan_id", "assessment_id"], name: "green_deal_assessments_green_deal_plan_id_assessment_id_idx", unique: true
  end

  create_table "scotland.green_deal_plans", id: false, force: :cascade do |t|
    t.boolean "cca_regulated"
    t.decimal "charge_uplift_amount"
    t.datetime "charge_uplift_date"
    t.jsonb "charges", default: "[]", null: false
    t.datetime "end_date"
    t.boolean "fixed_interest_rate"
    t.string "green_deal_plan_id"
    t.decimal "interest_rate"
    t.jsonb "measures", default: "[]", null: false
    t.boolean "measures_removed"
    t.string "provider_email"
    t.string "provider_name"
    t.string "provider_telephone"
    t.jsonb "savings", default: "[]", null: false
    t.datetime "start_date"
    t.boolean "structure_changed"
    t.index ["green_deal_plan_id"], name: "index_green_deal_plans_on_green_deal_plan_id", unique: true
  end

  create_table "scotland.linked_assessments", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.string "linked_assessment_id", null: false
    t.index ["linked_assessment_id"], name: "linked_assessments_linked_assessment_id_idx"
  end

  create_table "scotland.overridden_lodgement_events", id: :bigint, default: -> { "nextval('public.overridden_lodgement_events_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "assessment_id"
    t.datetime "created_at", null: false
    t.jsonb "rule_triggers", default: []
  end

  add_foreign_key "scotland.assessments", "public.assessors", column: "scheme_assessor_id", primary_key: "scheme_assessor_id"
  add_foreign_key "scotland.assessments_country_ids", "public.countries", primary_key: "country_id", name: "fks_assessments_country_ids_countries"
  add_foreign_key "scotland.assessments_xml", "scotland.assessments", primary_key: "assessment_id", name: "fk_scotland_assessment_xml_scotland_assessments"
  add_foreign_key "scotland.green_deal_assessments", "scotland.assessments", primary_key: "assessment_id", name: "fk_scotland_green_deal_assessments_scotland_assessments"
  add_foreign_key "scotland.green_deal_assessments", "scotland.green_deal_plans", primary_key: "green_deal_plan_id"
end
