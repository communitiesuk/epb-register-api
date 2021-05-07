module UseCase
  class ImportAddressBaseData
    def execute(address_data_line)
      unless Helper::AddressBaseFilter.filter_certifiable_addresses(
        address_data_line[:CLASS],
      )
        return nil
      end

      uprn = ActiveRecord::Base.connection.quote(address_data_line[:UPRN])

      lines = []

      # If there is a SAO_text value, it should appear on a separate line above the PAO_text line (or the pao number/range + street line where there is no PAO_text value).
      # If there is a SAO_text value, it should always appear on its own line.
      lines.push(address_data_line[:SAO_TEXT])

      street = ""

      # If there is a PAO_text value, it should always appear on the line above the street name (or on the line above the <pao number string> + <street name> where there is a PAO number/range).
      if address_data_line[:PAO_TEXT] != ""
        # If there is a SAO number/range value, it should be inserted either on the same line as the PAO_text (if there is a PAO_text value), if there are both PAO_text and a PAO number/range, then the SAO number/range should appear on the same line as the PAO_text, and the PAO number/range should appear on the street line.
        line = []
        if address_data_line[:SAO_START_NUMBER] != "" || address_data_line[:SAO_START_SUFFIX] != "" ||
            address_data_line[:SAO_END_NUMBER] != "" || address_data_line[:SAO_END_SUFFIX] != ""
          line.push(
            [
              [address_data_line[:SAO_START_NUMBER], address_data_line[:SAO_START_SUFFIX]].join(""),
              [address_data_line[:SAO_END_NUMBER], address_data_line[:SAO_END_SUFFIX]].join(""),
            ].reject(&:blank?).join("-"),
          )
        end
        line.push(address_data_line[:PAO_TEXT])
        lines.push(line.reject(&:blank?).join(" "))
        # or on the same line as the PAO number/range + street name (if there is only a PAO number/range value and no PAO_text value).
      elsif address_data_line[:SAO_START_NUMBER] != "" || address_data_line[:SAO_START_SUFFIX] != "" ||
          address_data_line[:SAO_END_NUMBER] != "" || address_data_line[:SAO_END_SUFFIX] != ""
        street =
          [
            [address_data_line[:SAO_START_NUMBER], address_data_line[:SAO_START_SUFFIX]].join(""),
            [address_data_line[:SAO_END_NUMBER], address_data_line[:SAO_END_SUFFIX]].join(""),
          ].reject(&:blank?).join("-")
      end

      # Generally, if there is a PAO number/range string, it should appear on the same line as the street
      if address_data_line[:PAO_START_NUMBER] != "" || address_data_line[:PAO_START_SUFFIX] != "" ||
          !address_data_line[:PAO_END_NUMBER] != "" || !address_data_line[:PAO_END_SUFFIX] != ""
        pao =
          [
            [address_data_line[:PAO_START_NUMBER], address_data_line[:PAO_START_SUFFIX]].join(""),
            [address_data_line[:PAO_END_NUMBER], address_data_line[:PAO_END_SUFFIX]].join(""),
          ].reject(&:blank?).join("-")
        street = [street, pao].reject(&:blank?).join(" ")
      end

      lines.push([street, address_data_line[:STREET_DESCRIPTION]].reject(&:blank?).join(" "))

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

      [
        "(#{uprn}",
        ActiveRecord::Base.connection.quote(postcode),
        ActiveRecord::Base.connection.quote(lines[0]),
        ActiveRecord::Base.connection.quote(lines[1]),
        ActiveRecord::Base.connection.quote(lines[2]),
        ActiveRecord::Base.connection.quote(lines[3]),
        ActiveRecord::Base.connection.quote(town) + ")",
      ].join(", ")
    end
  end
end
