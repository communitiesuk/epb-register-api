class AddCorrectForgeinKeysToScotlandSchemaTables < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key "scotland.assessments_xml",
                    "scotland.assessments",
                    column: :assessment_id, primary_key: :assessment_id
  end
end
