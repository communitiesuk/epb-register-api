class CreatePostcodeOutcodes < ActiveRecord::Migration[6.0]
  def change
    create_table :postcode_outcode_geolocations do |t|
      t.string :outcode
      t.decimal :latitude
      t.decimal :longitude
    end
  end
end
