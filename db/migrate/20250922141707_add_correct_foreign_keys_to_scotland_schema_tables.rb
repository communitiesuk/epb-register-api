class AddCorrectForeignKeysToScotlandSchemaTables < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key "scotland.assessments_xml",
                    "scotland.assessments",
                    column: :assessment_id,
                    primary_key: :assessment_id,
                    name: "fk_scotland_assessment_xml_scotland_assessments"
    add_foreign_key "scotland.green_deal_assessments",
                    "scotland.assessments",
                    column: :assessment_id,
                    primary_key: :assessment_id,
                    name: "fk_scotland_green_deal_assessments_scotland_assessments"
  end
end
