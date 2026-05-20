module Domain
  class Address
    attr_accessor :address_id, :existing_assessments

    attr_reader :line1, :line2, :line3, :line4, :town, :postcode, :source

    def initialize(
      address_id:,
      line1:,
      line2:,
      line3:,
      line4:,
      town:,
      postcode:,
      country:,
      source:,
      existing_assessments:
    )
      @address_id = address_id
      @line1 = line1
      @line2 = line2
      @line3 = line3
      @line4 = line4
      @town = town
      @postcode = postcode
      @country = country
      @source = source
      @existing_assessments = existing_assessments
    end

    def to_hash
      hash =       {
        address_id: @address_id,
        line1: @line1,
        line2: @line2,
        line3: @line3,
        line4: @line4,
        town: @town,
        postcode: @postcode,
        source: @source,
        existing_assessments: @existing_assessments,
      }

      if Helper::Toggles.enabled?("register-api-add-country-in-address")
        hash[:country] = @country
      end

      hash
    end
  end
end
