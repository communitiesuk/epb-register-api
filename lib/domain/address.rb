module Domain
  class Address
    attr_accessor :existing_assessments
    attr_reader :address_id,
                :line1,
                :line2,
                :line3,
                :line4,
                :town,
                :postcode,
                :source

    def initialize(
      address_id:,
      line1:,
      line2:,
      line3:,
      line4:,
      town:,
      postcode:,
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
      @source = source
      @existing_assessments = existing_assessments
    end

    def to_hash
      {
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
    end
  end
end
