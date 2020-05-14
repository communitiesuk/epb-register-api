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

ActiveRecord::Schema.define(version: 2020_05_14_115407) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assessments", primary_key: "assessment_id", id: :string, force: :cascade do |t|
    t.datetime "date_of_assessment"
    t.datetime "date_registered"
    t.string "dwelling_type"
    t.string "type_of_assessment"
    t.decimal "total_floor_area"
    t.string "address_summary"
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
    t.string "related_party_disclosure_number"
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
  add_foreign_key "assessors", "schemes", column: "registered_by", primary_key: "scheme_id"
  add_foreign_key "domestic_epc_energy_improvements", "assessments", primary_key: "assessment_id"
end
