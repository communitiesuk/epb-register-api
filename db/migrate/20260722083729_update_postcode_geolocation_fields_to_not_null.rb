class UpdatePostcodeGeolocationFieldsToNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :postcode_geolocation, :region, false
    change_column_null :postcode_geolocation, :latitude, false
    change_column_null :postcode_geolocation, :longitude, false

    change_column_null :postcode_outcode_geolocations, :region, false
    change_column_null :postcode_outcode_geolocations, :latitude, false
    change_column_null :postcode_outcode_geolocations, :longitude, false
  end
end
