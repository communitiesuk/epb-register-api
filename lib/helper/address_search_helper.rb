module Helper
  class AddressSearchHelper
    def self.where_postcode_and_number_clause
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

    def self.where_postcode_and_name_clause
      <<-SQL
        a.address_line1 ILIKE $2 OR a.address_line2 ILIKE $2
      SQL
    end

    def self.bind_postcode_and_number(postcode, building_number)
      [
        string_attribute("postcode", Helper::ValidatePostcodeHelper.format_postcode(postcode)),
        string_attribute("number_in_middle", sprintf('\D+%s\D+', building_number)),
        string_attribute("number_at_start", sprintf('^%s\D+', building_number)),
        string_attribute("number_at_end", sprintf('\D+%s$', building_number)),
        string_attribute("number_exact", building_number),
      ]
    end

    def self.bind_postcode_and_name(postcode, building_name)
      [
        string_attribute("postcode", Helper::ValidatePostcodeHelper.format_postcode(postcode)),
        string_attribute("building_name", "%#{building_name}%"),
      ]
    end

    def self.string_attribute(name, value)
      ActiveRecord::Relation::QueryAttribute.new(
        name,
        value,
        ActiveRecord::Type::String.new,
      )
    end
  end
end
