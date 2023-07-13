describe Domain::AssessmentEcoPlusDetails do
  let(:arguments) do
    {
      type_of_assessment: "RdSAP",
      address: {
        address_line1: "22 Acacia Avenue",
        address_line2: "Upper Wellgood",
        address_line3: "",
        address_line4: "",
        town: "Fulchester",
        postcode: "FL23 4JA",
      },
      uprn: "UPRN-001234567890",
      lodgement_date: "2020-02-29",
      current_energy_efficiency_rating: 62,
      current_energy_efficiency_band: "c",
      potential_energy_efficiency_rating: 1,
      potential_energy_efficiency_band: "a",
      property_type: "Mid-floor flat",
      built_form: "End-Terrace",
      main_heating_description: "Boiler and radiators, mains gas",
      walls_description: [
        "Solid brick, as built, no insulation",
        "Cavity wall, as built, insulated (assumed)",
      ],
      roof_description: [
        "Pitched, 250 mm loft insulation",
        "Pitched, limited insulation (assumed)",
      ],
      cavity_wall_insulation_recommended: false,
      loft_insulation_recommended: true,
    }
  end

  let(:expected_data) do
    {
      type_of_assessment: "RdSAP",
      address: {
        address_line1: "22 Acacia Avenue",
        address_line2: "Upper Wellgood",
        address_line3: "",
        address_line4: "",
        town: "Fulchester",
        postcode: "FL23 4JA",
      },
      uprn: "001234567890",
      lodgement_date: "2020-02-29",
      current_energy_efficiency_rating: 62,
      current_energy_efficiency_band: "c",
      potential_energy_efficiency_rating: 1,
      potential_energy_efficiency_band: "a",
      property_type: "Mid-floor flat",
      built_form: "End-Terrace",
      main_heating_description: "Boiler and radiators, mains gas",
      walls_description: [
        "Solid brick, as built, no insulation",
        "Cavity wall, as built, insulated (assumed)",
      ],
      roof_description: [
        "Pitched, 250 mm loft insulation",
        "Pitched, limited insulation (assumed)",
      ],
      cavity_wall_insulation_recommended: false,
      loft_insulation_recommended: true,
    }
  end

  let(:domain) { described_class.new(**arguments) }

  describe "#to_hash" do
    it "returns the expected data" do
      expect(domain.to_hash).to eq expected_data
    end
  end
end
