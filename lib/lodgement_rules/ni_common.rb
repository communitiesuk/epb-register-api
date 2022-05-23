module LodgementRules

  class NiCommon


    def validate(schema_name:, address:, migrated: false)
      @schema_name = schema_name
      @address = address

      return true if migrated

      raise Boundary::InvalidNiAssessment.new("Assessment with a Northern Ireland schema must have a property postcode starting with BT") unless has_valid_postcode?
      raise Boundary::InvalidNiAssessment.new("Assessment with a Northern Ireland postcode must be lodged with a NI Schema") unless has_valid_schema?
    end


    private
    def has_valid_postcode?
      return false if @schema_name.include?("NI") && !@address[:postcode].strip.upcase.starts_with?("BT")
      true
    end

    def has_valid_schema?
      return false if @address[:postcode].strip.upcase.starts_with?("BT") && !@schema_name.include?("NI")
        true
    end

    end
  end

