class AlterAssessorsRenameColumnDomesticEpQualification < ActiveRecord::Migration[
  6.0
]
  def change
    rename_column :assessors,
                  :domestic_energy_performance_qualification,
                  :domestic_rd_sap_qualification
  end
end
