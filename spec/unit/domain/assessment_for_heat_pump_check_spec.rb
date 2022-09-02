describe Domain::AssessmentForHeatPumpCheck do
  subject(:heat_pump_check_assessment) do
    described_class.new(**fields)
  end

  let(:fields) do
    {
      address: {
        address_line1: "22 Acacia Avenue",
        address_line2: "Upper Wellgood",
        address_line3: "",
        address_line4: "",
        town: "Nether Wallop",
        postcode: "BS3 3FG",
      },
      lodgement_date: "2020-02-29",
      is_latest_assessment_for_address: true,
      property_type: "Mid-floor flat",
      built_form: "End-Terrace",
      property_age_band: "D",
      walls_description: [
        "Solid brick, as built, no insulation",
        "Cavity wall, as built, insulated (assumed)",
      ],
      roof_description: [
        "Pitched, 250 mm loft insulation",
        "Pitched, limited insulation (assumed)",
      ],
      windows_description: [
        "Fully double glazed",
      ],
      main_fuel_type: "Natural Gas",
      total_floor_area: 55,
      has_mains_gas: true,
    }
  end

  it "represents the domain object as a hash" do
    expect(heat_pump_check_assessment.to_hash).to eq fields
  end
end
