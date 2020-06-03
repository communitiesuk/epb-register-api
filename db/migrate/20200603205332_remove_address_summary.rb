class RemoveAddressSummary < ActiveRecord::Migration[6.0]
  def change
    remove_column :assessments, :address_summary
  end
end
