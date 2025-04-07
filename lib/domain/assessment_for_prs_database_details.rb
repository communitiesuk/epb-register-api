module Domain
  class AssessmentForPrsDatabaseDetails
    def initialize(gateway_response:)
      @gateway_response = gateway_response
    end

    def to_hash
      {
        address: {
          address_line1: @gateway_response["address_line1"] || "",
          address_line2: @gateway_response["address_line2"] || "",
          address_line3: @gateway_response["address_line3"] || "",
          address_line4: @gateway_response["address_line4"] || "",
          town: @gateway_response["town"],
          postcode: @gateway_response["postcode"],
        },
        current_energy_efficiency_rating: @gateway_response["current_energy_efficiency_rating"],
        epc_rrn: @gateway_response["epc_rrn"],
        expiry_date: @gateway_response["expiry_date"],
        latest_epc_rrn_for_address: @gateway_response["latest_epc_rrn_for_address"],
        current_energy_efficiency_band: Helper::EnergyBandCalculator.domestic(@gateway_response["current_energy_efficiency_rating"]),
      }
    end
  end
end
