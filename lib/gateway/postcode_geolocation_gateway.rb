module Gateway
  class PostcodeGeolocationGateway
    def clean_up
      db = ActiveRecord::Base.connection

      db.drop_table :postcode_geolocation_tmp, if_exists: true
      db.drop_table :postcode_geolocation_legacy, if_exists: true
      puts "[#{Time.now}] Dropped postcode_geolocation_tmp / postcode_geolocation_legacy tables"

      db.drop_table :postcode_outcode_geolocations_tmp, if_exists: true
      db.drop_table :postcode_outcode_geolocations_legacy, if_exists: true
      puts "[#{Time.now}] Dropped postcode_outcode_geolocations_tmp / postcode_outcode_geolocations_legacy tables"
    end
  end
end
