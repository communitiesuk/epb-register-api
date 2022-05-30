module Helper
  class AddressSearchHelper
    def self.postcode_and_number_expression
      <<-SQL
        AND
        a.postcode = $1 AND
        (
          a.address_line1 ~ $2
          OR a.address_line2 ~ $2
          OR a.address_line1 ~ $3
          OR a.address_line2 ~ $3
          OR a.address_line1 ~ $4
          OR a.address_line2 ~ $4
          OR a.address_line1 = $5
          OR a.address_line2 = $5
        )
      SQL
    end

    def self.clean_building_identifier(building_identifier)
      building_identifier&.delete!("()|:*!\\") || building_identifier
    end
  end
end
