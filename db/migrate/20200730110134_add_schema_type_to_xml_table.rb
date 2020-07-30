class AddSchemaTypeToXmlTable < ActiveRecord::Migration[6.0]
  def change
    add_column :assessments_xml, :schema_type, :string
  end
end
