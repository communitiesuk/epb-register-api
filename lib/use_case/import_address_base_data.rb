module UseCase
  class ImportAddressBaseData
    ImportedAddress =
      Struct.new(:uprn, :postcode, :lines, :town, :country_code, keyword_init: true)

    def execute(address_data_line)
      unless Helper::AddressBaseFilter.filter_certifiable_addresses(address_data_line)
        return nil
      end

      uses_delivery_point =
        address_data_line[:CLASS].start_with?("R") &&
        !address_data_line[:UDPRN].nil?
      address_type = uses_delivery_point ? "Delivery Point" : "Geographic"

      imported_address =
        if uses_delivery_point
          create_delivery_point_address(address_data_line)
        else
          create_geographic_address(address_data_line)
        end

      [
        "(#{ActiveRecord::Base.connection.quote(imported_address.uprn)}",
        ActiveRecord::Base.connection.quote(imported_address.postcode),
        ActiveRecord::Base.connection.quote(imported_address.lines[0]),
        ActiveRecord::Base.connection.quote(imported_address.lines[1]),
        ActiveRecord::Base.connection.quote(imported_address.lines[2]),
        ActiveRecord::Base.connection.quote(imported_address.lines[3]),
        ActiveRecord::Base.connection.quote(imported_address.town),
        ActiveRecord::Base.connection.quote(address_data_line[:CLASS]),
        ActiveRecord::Base.connection.quote(address_type),
        "#{ActiveRecord::Base.connection.quote(imported_address.country_code)})",
      ].join(", ")
    end

  private

    def create_geographic_address(address_data_line)
      uprn = address_data_line[:UPRN]

      lines = []

      # If there is a SAO_text value, it should appear on a separate line above the PAO_text line (or the pao number/range + street line where there is no PAO_text value).
      # If there is a SAO_text value, it should always appear on its own line.
      lines.push(address_data_line[:SAO_TEXT])

      street = ""

      # If there is a PAO_text value, it should always appear on the line above the street name (or on the line above the <pao number string> + <street name> where there is a PAO number/range).
      if address_data_line[:PAO_TEXT] != ""
        # If there is a SAO number/range value, it should be inserted either on the same line as the PAO_text (if there is a PAO_text value), if there are both PAO_text and a PAO number/range, then the SAO number/range should appear on the same line as the PAO_text, and the PAO number/range should appear on the street line.
        line = []
        if address_data_line[:SAO_START_NUMBER] != "" ||
            address_data_line[:SAO_START_SUFFIX] != "" ||
            address_data_line[:SAO_END_NUMBER] != "" ||
            address_data_line[:SAO_END_SUFFIX] != ""
          line.push(
            [
              [
                address_data_line[:SAO_START_NUMBER],
                address_data_line[:SAO_START_SUFFIX],
              ].join(""),
              [
                address_data_line[:SAO_END_NUMBER],
                address_data_line[:SAO_END_SUFFIX],
              ].join(""),
            ].reject(&:blank?).join("-"),
          )
        end
        line.push(address_data_line[:PAO_TEXT])
        lines.push(line.reject(&:blank?).join(" "))
        # or on the same line as the PAO number/range + street name (if there is only a PAO number/range value and no PAO_text value).
      elsif address_data_line[:SAO_START_NUMBER] != "" ||
          address_data_line[:SAO_START_SUFFIX] != "" ||
          address_data_line[:SAO_END_NUMBER] != "" ||
          address_data_line[:SAO_END_SUFFIX] != ""
        street =
          [
            [
              address_data_line[:SAO_START_NUMBER],
              address_data_line[:SAO_START_SUFFIX],
            ].join(""),
            [
              address_data_line[:SAO_END_NUMBER],
              address_data_line[:SAO_END_SUFFIX],
            ].join(""),
          ].reject(&:blank?).join("-")
      end

      # Generally, if there is a PAO number/range string, it should appear on the same line as the street
      if address_data_line[:PAO_START_NUMBER] != "" ||
          address_data_line[:PAO_START_SUFFIX] != "" ||
          address_data_line[:PAO_END_NUMBER] != "" ||
          address_data_line[:PAO_END_SUFFIX] != ""
        pao =
          [
            [
              address_data_line[:PAO_START_NUMBER],
              address_data_line[:PAO_START_SUFFIX],
            ].join(""),
            [
              address_data_line[:PAO_END_NUMBER],
              address_data_line[:PAO_END_SUFFIX],
            ].join(""),
          ].reject(&:blank?).join("-")
        street = [street, pao].reject(&:blank?).join(" ")
      end

      lines.push(
        [street, address_data_line[:STREET_DESCRIPTION]].reject(&:blank?).join(
          " ",
        ),
      )

      # The locality name (if present) should appear on a separate line beneath the street description,
      lines.push(address_data_line[:LOCALITY])

      # followed by the town name on the line below it. If there is no locality name, the town name should appear alone on the line beneath the street description.
      if address_data_line[:LOCALITY] != address_data_line[:TOWN_NAME]
        lines.push(address_data_line[:TOWN_NAME])
      end

      lines = lines.reject(&:blank?)

      # Finally, the postcode locator, if present, should be inserted on the final line of the address.
      postcode =
        if address_data_line[:POSTCODE] == ""
          address_data_line[:POSTCODE_LOCATOR]
        else
          address_data_line[:POSTCODE]
        end

      # administrative_location if town is not the same
      #
      # STREET_DESCRIPTION

      town = address_data_line[:TOWN_NAME]

      lines.pop if lines[-1] == town

      country_code = address_data_line[:COUNTRY]

      ImportedAddress.new(
        uprn:,
        postcode:,
        lines:,
        town:,
        country_code:,
      )
    end

    def create_delivery_point_address(address_data_line)
      if address_data_line[:UDPRN].nil?
        raise ArgumentError,
              "Unable to create Delivery Point Address from address data line with no UDPRN"
      end

      uprn = address_data_line[:UPRN]

      lines =
        %i[
          DEPARTMENT_NAME
          RM_ORGANISATION_NAME
          SUB_BUILDING_NAME
          BUILDING_NAME
          BUILDING_NUMBER
          PO_BOX_NUMBER
          DEPENDENT_THOROUGHFARE
          THOROUGHFARE
          DOUBLE_DEPENDENT_LOCALITY
          DEPENDENT_LOCALITY
        ].map { |key| address_data_line[key].to_s }.reject do |line|
          line.nil? || line.empty?
        end

      lines = combine_street_line(lines)

      lines = compact_excess_lines(lines) if lines.length >= 5

      postcode = address_data_line[:POSTCODE]

      town = address_data_line[:POST_TOWN]

      country_code = address_data_line[:COUNTRY]

      ImportedAddress.new(
        uprn:,
        postcode:,
        lines:,
        town:,
        country_code:,
      )
    end

    def compact_excess_lines(lines)
      lines[0...3].push(lines[3..].join(", "))
    end

    def combine_street_line(lines)
      lines.inject([]) do |carry, val|
        if /^\d+[A-Z]?$/.match?(carry[-1])
          carry[0...-1].push([carry[-1], val].join(" "))
        else
          carry << val
          carry
        end
      end
    end
  end
end
