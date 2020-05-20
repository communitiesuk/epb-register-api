class RenameLodgementAttemptsTableToAssessmentsXml < ActiveRecord::Migration[
  6.0
]
  def change
    rename_table :lodgement_attempts, :assessments_xml
  end
end
