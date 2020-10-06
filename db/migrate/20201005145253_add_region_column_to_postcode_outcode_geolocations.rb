class AddRegionColumnToPostcodeOutcodeGeolocations < ActiveRecord::Migration[6.0]
  def change
    add_column :postcode_outcode_geolocations, :region, :string
  end
end
