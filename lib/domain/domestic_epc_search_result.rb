module Domain
  class DomesticEpcSearchResult
    def initialize(
      assessment_id:,
      address_line1:,
      address_line2:,
      address_line3:,
      address_line4:,
      town:,
      postcode:
    )
      @epc_rrn = assessment_id
      @address = { addressLine1: address_line1, addressLine2: address_line2, addressLine3: address_line3, addressLine4: address_line4, town:, postcode: }
    end

    def to_hash
      {
        epc_rrn: @epc_rrn,
        address: @address,
      }
    end

    def rrn
      @epc_rrn
    end
  end
end
