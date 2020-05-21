module Domain
  class Address
    attr_reader :building_reference_number,
                :line1,
                :line2,
                :line3,
                :town,
                :postcode,
                :source

    def initialize(
      building_reference_number:,
      line1:,
      line2:,
      line3:,
      town:,
      postcode:,
      source:
    )
      @building_reference_number = building_reference_number
      @line1 = line1
      @line2 = line2
      @line3 = line3
      @town = town
      @postcode = postcode
      @source = source
    end

    def to_hash
      {
        building_reference_number: @building_reference_number,
        line1: @line1,
        line2: @line2,
        line3: @line3,
        town: @town,
        postcode: @postcode,
        source: @source,
      }
    end
  end
end
