class CreateLprnToRrnTable < ActiveRecord::Migration[6.0]
  def change
    create_table :lprn_to_rrn, primary_key: :lprn, id: :string do |t|
      t.string :rrn, index: true, null: false
      t.datetime :created_at, null: false
    end
  end
end
