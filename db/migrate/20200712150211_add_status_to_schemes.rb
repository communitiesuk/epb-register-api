class AddStatusToSchemes < ActiveRecord::Migration[6.0]
  def change
    add_column :schemes, :active, :boolean, default: true
  end
end
