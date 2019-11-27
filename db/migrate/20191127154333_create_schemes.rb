class CreateSchemes < ActiveRecord::Migration[6.0]
  def change
    create_table :schemes, primary_key: :scheme_id do |t|
      t.string :name
    end

    add_index :schemes, :name, unique: true
  end
end
