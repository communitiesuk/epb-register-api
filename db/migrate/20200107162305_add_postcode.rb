class AddPostcode < ActiveRecord::Migration[6.0]
  def change
    add_column :assessors, :search_results_comparison_postcode, :string
  end
end
