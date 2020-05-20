class ReorganiseColumnsForAssessmentsXml < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments_xml, :status
    remove_column :assessments_xml, :failure_reason
    remove_column :assessments_xml, :submitted_at
    remove_column :assessments_xml, :scheme_id
    remove_column :assessments_xml, :request_header
    remove_column :assessments_xml, :url
    remove_column :assessments_xml, :request_body

    add_column :assessments_xml, :xml, :xml
    rename_column :assessments_xml, :id, :assessment_id

    change_column :assessments_xml, :assessment_id, :string
    change_column :assessments_xml, :xml, :xml

    add_foreign_key :assessments_xml,
                    :assessments,
                    column: :assessment_id,
                    primary_key: :assessment_id
  end
end
