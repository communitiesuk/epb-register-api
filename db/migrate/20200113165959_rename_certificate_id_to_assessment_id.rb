class RenameCertificateIdToAssessmentId < ActiveRecord::Migration[6.0]
  def self.up
    rename_column :domestic_energy_assessments, :certificate_id, :assessment_id
  end

  def self.down
    rename_column :domestic_energy_assessments, :assessment_id, :certificate_id
  end
end
