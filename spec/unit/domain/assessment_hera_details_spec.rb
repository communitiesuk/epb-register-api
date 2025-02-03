describe Domain::AssessmentHeraDetails do
  let(:arguments) do
    {
      assessment_summary:,
      domestic_digest:,
    }
  end

  let(:assessment_summary) do
    { superseded_by: nil }
  end

  let(:domestic_digest) do
    {
      type_of_assessment: "RdSAP",
      assessment_id: "0000-0000-0000-0000-0000",
      date_of_registration: "2020-02-29",
      address: {
        address_line1: "22 Acacia Avenue",
        address_line2: "Upper Wellgood",
        address_line3: "",
        address_line4: "",
        town: "Nether Wallop",
        postcode: "BS3 3FG",
      },
      dwelling_type: "Mid-floor flat",
      built_form: "End-Terrace",
      main_dwelling_construction_age_band_or_year: "D",
      property_summary: [
        { energy_efficiency_rating: 1, environmental_efficiency_rating: 1, name: "wall", description: "Solid brick, as built, no insulation" },
        { energy_efficiency_rating: 4, environmental_efficiency_rating: 4, name: "wall", description: "Cavity wall, as built, insulated (assumed)" },
        { energy_efficiency_rating: 2, environmental_efficiency_rating: 2, name: "roof", description: "Pitched, 250 mm loft insulation" },
        { energy_efficiency_rating: 4, environmental_efficiency_rating: 4, name: "roof", description: "Pitched, limited insulation (assumed)" },
        { energy_efficiency_rating: 0, environmental_efficiency_rating: 0, name: "floor", description: "Suspended, no insulation (assumed)" },
        { energy_efficiency_rating: 0, environmental_efficiency_rating: 0, name: "floor", description: "Solid, no insulation (assumed)" },
        { energy_efficiency_rating: 3, environmental_efficiency_rating: 3, name: "window", description: "Fully double glazed" },
        { energy_efficiency_rating: 3, environmental_efficiency_rating: 1, name: "main_heating", description: "Boiler and radiators, anthracite" },
        { energy_efficiency_rating: 4, environmental_efficiency_rating: 4, name: "main_heating", description: "Boiler and radiators, mains gas" },
        { energy_efficiency_rating: 4, environmental_efficiency_rating: 4, name: "main_heating_controls", description: "Programmer, room thermostat and TRVs" },
        { energy_efficiency_rating: 5, environmental_efficiency_rating: 5, name: "main_heating_controls", description: "Time and temperature zone control" },
        { energy_efficiency_rating: 4, environmental_efficiency_rating: 4, name: "hot_water", description: "From main system" },
        { energy_efficiency_rating: 4, environmental_efficiency_rating: 4, name: "lighting", description: "Low energy lighting in 50% of fixed outlets" },
        { energy_efficiency_rating: 0, environmental_efficiency_rating: 0, name: "secondary_heating", description: "Room heaters, electric" },
      ],
      main_heating_category: "Boiler and radiators, mains gas",
      main_fuel_type: "Natural Gas",
      has_hot_water_cylinder: "false",
      total_floor_area: "55",
      has_mains_gas: "Y",
      current_energy_efficiency_rating: 50,
      potential_energy_efficiency_rating: 72,
      type_of_property: "House",
      recommended_improvements: [
        { energy_performance_rating_improvement: 50, environmental_impact_rating_improvement: 50, green_deal_category_code: "1", improvement_category: "6", improvement_code: "5", improvement_description: nil, improvement_title: "", improvement_type: "Z3", indicative_cost: "£100 - £350", sequence: 1, typical_saving: "360", energy_performance_band_improvement: "e" },
        { energy_performance_rating_improvement: 60, environmental_impact_rating_improvement: 64, green_deal_category_code: "3", improvement_category: "2", improvement_code: "1", improvement_description: nil, improvement_title: "", improvement_type: "Z2", indicative_cost: "2000", sequence: 2, typical_saving: "99", energy_performance_band_improvement: "d" },
        { energy_performance_rating_improvement: 60, environmental_impact_rating_improvement: 64, green_deal_category_code: "3", improvement_category: "2", improvement_code: nil, improvement_description: "Improvement desc", improvement_title: "", improvement_type: "Z2", indicative_cost: "1000", sequence: 3, typical_saving: "99", energy_performance_band_improvement: "d" },
      ],
      photo_supply: 0,
      main_heating_controls: ["Programmer, room thermostat and TRVs", "Time and temperature zone control"],
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
      photo_supply: 0,
      main_heating_controls: ["Programmer, room thermostat and TRVs", "Time and temperature zone control"],
    }
  end

  let(:expected_latest) { expected_data }
  let(:expected_not_latest) do
    clone = expected_latest.clone
    clone[:is_latest_assessment_for_address] = false
    clone
  end
  let(:expected_with_nulls) do
    clone = expected_latest.clone
    clone[:property_type] = nil
    clone[:built_form] = nil
    clone[:property_age_band] = nil
    clone[:walls_description] = []
    clone[:floor_description] = []
    clone[:roof_description] = []
    clone[:windows_description] = []
    clone[:main_heating_description] = nil
    clone[:main_fuel_type] = nil
    clone
  end

  let(:domain) { described_class.new(**arguments) }

  context "when the details provided are from the property's latest assessment" do
    it "returns the expected data" do
      expect(domain.to_hash).to eq expected_latest
    end
  end

  context "when the details provided are not from the property's latest assessment" do
    before do
      assessment_summary[:superseded_by] = "RRN-0000-0000-0000-0000-0001"
    end

    it "returns the expected data with a nil for the uprn" do
      expect(domain.to_hash).to eq expected_not_latest
    end
  end

  context "when there are nulls in the xml" do
    before do
      domestic_digest[:dwelling_type] = nil
      domestic_digest[:built_form] = nil
      domestic_digest[:main_dwelling_construction_age_band_or_year] = nil
      domestic_digest[:property_summary] =
        { energy_efficiency_rating: 3, environmental_efficiency_rating: 1, name: "main_heating", description: "Boiler and radiators, anthracite" },
        { energy_efficiency_rating: 4, environmental_efficiency_rating: 4, name: "main_heating", description: "Boiler and radiators, mains gas" },
        { energy_efficiency_rating: 4, environmental_efficiency_rating: 4, name: "main_heating_controls", description: "Programmer, room thermostat and TRVs" },
        { energy_efficiency_rating: 5, environmental_efficiency_rating: 5, name: "main_heating_controls", description: "Time and temperature zone control" },
        { energy_efficiency_rating: 4, environmental_efficiency_rating: 4, name: "hot_water", description: "From main system" },
        { energy_efficiency_rating: 4, environmental_efficiency_rating: 4, name: "lighting", description: "Low energy lighting in 50% of fixed outlets" },
        { energy_efficiency_rating: 0, environmental_efficiency_rating: 0, name: "secondary_heating", description: "Room heaters, electric" }
      domestic_digest[:main_heating_category] = nil
      domestic_digest[:main_fuel_type] = nil
    end

    it "returns the expected data" do
      expect(domain.to_hash).to eq expected_with_nulls
    end
  end
end
