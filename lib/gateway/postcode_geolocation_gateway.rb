module Gateway
  class PostcodeGeolocationGateway
    def initialize
      @db = ActiveRecord::Base.connection
    end

    def clean_up
      @db.drop_table :postcode_geolocation_legacy, if_exists: true
      puts "[#{Time.now}] Dropped postcode_geolocation_tmp / postcode_geolocation_legacy tables"

      @db.drop_table :postcode_outcode_geolocations_tmp, if_exists: true
      @db.drop_table :postcode_outcode_geolocations_legacy, if_exists: true
      puts "[#{Time.now}] Dropped postcode_outcode_geolocations_tmp / postcode_outcode_geolocations_legacy tables"
    end

    def create_postcode_table
      unless @db.table_exists?(:postcode_geolocation_tmp)
        @db.create_table :postcode_geolocation_tmp, primary_key: :postcode, id: :string, force: :cascade do |t|
          t.decimal :latitude
          t.decimal :longitude
          t.string :region
        end
        puts "[#{Time.now}] Created empty postcode_geolocation_tmp table"
      end
    end

    def create_outcode_table
      unless @db.table_exists?(:postcode_outcode_geolocations_tmp)
        @db.create_table :postcode_outcode_geolocations_tmp, primary_key: :outcode, id: :string, force: :cascade do |t|
          t.decimal :latitude
          t.decimal :longitude
          t.string :region
        end
        puts "[#{Time.now}] Created empty postcode_outcode_geolocations_tmp table"
      end
    end

    def switch_postcode_table
      @db.rename_table :postcode_geolocation, :postcode_geolocation_legacy
      puts "[#{Time.now}] Renamed table postcode_geolocation to postcode_geolocation_legacy"

      @db.rename_table :postcode_geolocation_tmp, :postcode_geolocation
      puts "[#{Time.now}] Renamed table postcode_geolocation_tmp to postcode_geolocation"
    end

    def switch_outcode_table
      @db.rename_table :postcode_outcode_geolocations, :postcode_outcode_geolocations_legacy
      puts "[#{Time.now}] Renamed table postcode_outcode_geolocations to postcode_outcode_geolocations_legacy"

      @db.rename_table :postcode_outcode_geolocations_tmp, :postcode_outcode_geolocations
      puts "[#{Time.now}] Renamed table postcode_outcode_geolocations_tmp to postcode_outcode_geolocations"
    end

    def insert_postcode_batch(postcode_buffer)
      batch = postcode_buffer.join("), (")
      @db.exec_query("INSERT INTO postcode_geolocation_tmp (postcode, latitude, longitude, region) VALUES(#{batch})")
    end

    def insert_outcodes(outcodes)
      batch = outcodes.map do |outcode, data|
        [
          @db.quote(outcode),
          (data[:latitude].reduce(:+) / data[:latitude].size.to_f),
          (data[:longitude].reduce(:+) / data[:longitude].size.to_f),
          @db.quote(data[:region].max_by { |i| data[:region].count(i) }),
        ].join(", ")
      end

      @db.exec_query("INSERT INTO postcode_outcode_geolocations_tmp (outcode, latitude, longitude, region) VALUES(#{batch.join('), (')})")
    end

  private

    def add_outcode(outcodes, new_outcode, lat, long, region)
      unless outcodes.key?(new_outcode)
        outcodes[new_outcode] = {
          latitude: [],
          longitude: [],
          region: [],
        }
      end

      outcodes[new_outcode][:latitude].push(lat.to_f)
      outcodes[new_outcode][:longitude].push(long.to_f)
      outcodes[new_outcode][:region].push(region)
    end
  end
end
