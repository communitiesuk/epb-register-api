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

ActiveRecord::Schema.define(version: 2020_06_23_143510) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "plpgsql"

  create_table "assessments", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.datetime "date_of_assessment"
    t.datetime "date_registered"
    t.string "dwelling_type"
    t.string "type_of_assessment"
    t.decimal "total_floor_area"
    t.integer "current_energy_efficiency_rating", limit: 2, default: 1, null: false
    t.integer "potential_energy_efficiency_rating", limit: 2, default: 2, null: false
    t.string "postcode"
    t.datetime "date_of_expiry", null: false
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "address_line4"
    t.string "town"
    t.string "scheme_assessor_id", null: false
    t.decimal "current_space_heating_demand"
    t.decimal "current_water_heating_demand"
    t.integer "impact_of_loft_insulation"
    t.integer "impact_of_cavity_insulation"
    t.integer "impact_of_solid_wall_insulation"
    t.boolean "opt_out", default: false
    t.decimal "current_carbon_emission", default: "0.0", null: false
    t.decimal "potential_carbon_emission", default: "0.0", null: false
    t.jsonb "property_summary", default: "[]", null: false
    t.integer "related_party_disclosure_number"
    t.string "related_party_disclosure_text"
    t.string "address_id"
    t.boolean "migrated", default: false
    t.datetime "cancelled_at"
    t.datetime "not_for_issue_at"
    t.string "tenure"
    t.string "property_age_band"
    t.index ["address_id"], name: "index_assessments_on_address_id"
    t.index ["postcode"], name: "index_assessments_on_postcode"
    t.index ["town"], name: "index_assessments_on_town"
  end

  create_table "assessments_xml", primary_key: "assessment_id", id: :string, default: "", force: :cascade do |t|
    t.xml "xml"
  end

  create_table "assessors", primary_key: "scheme_assessor_id", id: :string, force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "middle_names"
    t.datetime "date_of_birth", null: false
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

  create_table "domestic_epc_energy_improvements", id: false, force: :cascade do |t|
    t.string "assessment_id"
    t.integer "sequence"
    t.string "improvement_code"
    t.string "indicative_cost"
    t.decimal "typical_saving"
    t.string "improvement_category"
    t.string "improvement_type"
    t.integer "energy_performance_rating_improvement"
    t.integer "environmental_impact_rating_improvement"
    t.string "green_deal_category_code"
    t.string "improvement_title"
    t.string "improvement_description"
  end

  create_table "green_deal_assessments", id: false, force: :cascade do |t|
    t.string "green_deal_plan_id"
    t.string "assessment_id"
  end

  create_table "green_deal_plans", primary_key: "green_deal_plan_id", id: :string, force: :cascade do |t|
    t.datetime "start_date"
    t.datetime "end_date"
    t.string "provider_name"
    t.string "provider_telephone"
    t.string "provider_email"
    t.decimal "interest_rate"
    t.boolean "fixed_interest_rate"
    t.decimal "charge_uplift_amount"
    t.datetime "charge_uplift_date"
    t.boolean "cca_regulated"
    t.boolean "structure_changed"
    t.boolean "measures_removed"
    t.jsonb "measures", default: "[]", null: false
    t.jsonb "charges", default: "[]", null: false
    t.jsonb "savings", default: "[]", null: false
  end

  create_table "postcode_geolocation", force: :cascade do |t|
    t.string "postcode"
    t.decimal "latitude"
    t.decimal "longitude"
  end

  create_table "postcode_outcode_geolocations", force: :cascade do |t|
    t.string "outcode"
    t.decimal "latitude"
    t.decimal "longitude"
  end

  create_table "schemes", primary_key: "scheme_id", force: :cascade do |t|
    t.string "name"
    t.index ["name"], name: "index_schemes_on_name", unique: true
  end

  add_foreign_key "assessments", "assessors", column: "scheme_assessor_id", primary_key: "scheme_assessor_id"
  add_foreign_key "assessments_xml", "assessments", primary_key: "assessment_id"
  add_foreign_key "assessors", "schemes", column: "registered_by", primary_key: "scheme_id"
  add_foreign_key "domestic_epc_energy_improvements", "assessments", primary_key: "assessment_id"
  add_foreign_key "green_deal_assessments", "assessments", primary_key: "assessment_id", name: "fk_assessment_id_assessments"
  add_foreign_key "green_deal_assessments", "green_deal_plans", primary_key: "green_deal_plan_id", name: "fk_green_deal_plan_id_green_deal_plans"
end
