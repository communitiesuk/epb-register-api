describe Domain::AssessmentHeraDetails do
  subject(:hera_details) do
    described_class.new(**fields)
  end

  let(:fields) do
    {
      type_of_assessment: "RdSAP",
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
      floor_description: [
        "Suspended, no insulation (assumed)",
        "Solid, no insulation (assumed)",
      ],
      roof_description: [
        "Pitched, 250 mm loft insulation",
        "Pitched, limited insulation (assumed)",
      ],
      windows_description: [
        "Fully double glazed",
      ],
      main_heating_description: "Boiler and radiators, mains gas",
      main_fuel_type: "Natural Gas",
      has_hot_water_cylinder: false,
    }
  end

  it "represents the domain object as a hash" do
    expect(hera_details.to_hash).to eq fields
  end
end
