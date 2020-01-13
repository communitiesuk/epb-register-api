class AddIndexToPostcode < ActiveRecord::Migration[6.0]
  def change
    add_index :assessors, :search_results_comparison_postcode
  end
end
