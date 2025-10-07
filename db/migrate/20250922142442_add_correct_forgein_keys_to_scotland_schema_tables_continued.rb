class AddCorrectForgeinKeysToScotlandSchemaTablesContinued < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key "scotland.assessments_country_ids",
                    "countries",
                    column: :country_id, primary_key: :country_id
    add_foreign_key "scotland.assessments",
                    "assessors",
                    column: :scheme_assessor_id, primary_key: :scheme_assessor_id
    add_foreign_key "scotland.green_deal_assessments",
                    "scotland.assessments",
                    column: :assessment_id, primary_key: :assessment_id
  end
end
