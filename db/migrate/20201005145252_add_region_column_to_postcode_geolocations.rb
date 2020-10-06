class AddRegionColumnToPostcodeGeolocations < ActiveRecord::Migration[6.0]
  def change
    add_column :postcode_geolocation, :region, :string
  end
end
