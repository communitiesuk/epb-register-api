module LodgementRules
  class LocationCommon
    def validate(schema_name:, xml_adaptor:, country_lookup:, migrated: false)
      @schema_name = schema_name
      @country_lookup = country_lookup
      @xml_adaptor = xml_adaptor

      return true if migrated

      has_valid_country?
      has_valid_country_code?
      raise Boundary::InvalidLocation, "Non-geographic and overseas postcodes are not allowed" unless has_valid_postcode?
    end

  private

    def has_valid_postcode?
      !@xml_adaptor&.postcode&.match?(UseCase::PostcodeData::NON_GEOGRAPHIC_OR_OVERSEAS)
    end

    def has_valid_country?
      if @schema_name.include?("-S-")
        if @country_lookup.in_channel_islands? ||
            @country_lookup.in_isle_of_man? ||
            (!@country_lookup.in_scotland? && @country_lookup.in_england?) ||
            @country_lookup.in_wales? ||
            @country_lookup.in_northern_ireland?
          raise Boundary::InvalidLocation, "Property address must be in Scotland"
        else
          true
        end
      elsif @country_lookup.in_channel_islands? ||
          @country_lookup.in_isle_of_man? ||
          (@country_lookup.in_scotland? && !@country_lookup.in_england?)
        raise Boundary::InvalidLocation, "Property address must be in England, Wales, or Northern Ireland"
      else
        true
      end
    end

    def has_valid_country_code?
      country_code = Helper::ClassHelper.method_or_nil(@xml_adaptor, :country_code)
      if @schema_name.include?("-S-")
        if !country_code.nil? && country_code != "SCT"
          raise Boundary::InvalidLocation, "Country code must be SCT"
        else
          true
        end
      elsif country_code == "SCT"
        raise Boundary::InvalidLocation, "Country code must not be SCT"
      else
        true
      end
    end
  end
end
