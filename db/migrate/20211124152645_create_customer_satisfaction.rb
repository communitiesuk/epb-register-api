class CreateCustomerSatisfaction < ActiveRecord::Migration[6.1]
  def change
    create_table :customer_satisfaction, id: false do |t|
      t.datetime  :month, primary_key: true
      t.integer   :very_satisfied, null: false
      t.integer   :satisfied, null: false
      t.integer   :neither, null: false
      t.integer   :dissatisfied, null: false
      t.integer   :very_dissatisfied, null: false
    end
  end
end
