module UseCase
  class ProcessPostcodeCsv
    REGION_CODES = {
      E12000001: "North East",
      E12000002: "North West",
      E12000003: "Yorkshire and The Humber",
      E12000004: "East Midlands",
      E12000005: "West Midlands",
      E12000006: "East of England",
      E12000007: "London",
      E12000008: "South East",
      E12000009: "South West",
      N99999999: "Northern Ireland",
      W99999999: "Wales",
    }.freeze

    def initialize(geolocation_gateway)
      @gateway = geolocation_gateway
      @db = ActiveRecord::Base.connection
    end

    def execute(postcode_csv, buffer_size: 10_000)
      @gateway.create_postcode_table

      postcode_geolocation_buffer = []
      outcodes = {}

      row_number = 1
      while (row = postcode_csv.shift)
        postcode = row["pcd7"]
        lat = row["lat"]
        long = row["long"]

        region = REGION_CODES[row["rgn25cd"].to_sym]

        # Only considers England, NI and Wales
        next if region.nil?

        postcode.insert(-4, " ") if postcode[-4] != " "
        new_outcode = postcode.split(" ")[0]

        postcode_geolocation_buffer << [@db.quote(postcode), lat, long, @db.quote(region)].join(", ")
        add_outcode(outcodes, new_outcode, lat, long, region)

        if (row_number % buffer_size).zero?
          @gateway.insert_postcode_batch(postcode_geolocation_buffer)
          postcode_geolocation_buffer.clear
        end

        row_number += 1
      end

      # Insert remaining postcode buffer
      unless postcode_geolocation_buffer.empty?
        @gateway.insert_postcode_batch(postcode_geolocation_buffer)
      end

      puts "[#{Time.now}] Inserted #{row_number} postcodes"

      @gateway.create_outcode_table
      unless outcodes.empty?
        @gateway.insert_outcodes(outcodes)
        puts "[#{Time.now}] Inserted #{outcodes.length} outcodes"
      end

      @gateway.switch_postcode_table
      @gateway.switch_outcode_table

      puts "[#{Time.now}] Postcode import completed"
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
