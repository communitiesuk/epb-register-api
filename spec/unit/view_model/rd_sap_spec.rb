require_relative "xml_view_test_helper"

describe ViewModel::RdSapWrapper do
  # You should only need to add to this list to test new CEPC schema
  supported_schema = [
    {
      schema_name: "RdSAP-Schema-20.0.0",
      xml_file: "spec/fixtures/samples/rdsap.xml",
      unsupported_fields: [],
      different_fields: {},
    },
    {
      schema_name: "RdSAP-Schema-NI-20.0.0",
      xml_file: "spec/fixtures/samples/rdsap-ni.xml",
      unsupported_fields: [],
      different_fields: {},
    },
  ].freeze

  # You should only need to add to this list to test new fields on all CEPC schema
  asserted_keys =
    asserted_keys = {
      type_of_assessment: "RdSAP",
      assessment_id: "0000-0000-0000-0000-0000",
      date_of_expiry: "2030-05-04",
      date_of_assessment: "2020-05-04",
      date_of_registration: "2020-05-04",
      date_registered: "2020-05-04",
      address_id: "UPRN-000000000000",
      address_line1: "1 Some Street",
      address_line2: "",
      address_line3: "",
      address_line4: "",
      town: "Post-Town1",
      postcode: "A0 0AA",
      address: {
        address_id: "UPRN-000000000000",
        address_line1: "1 Some Street",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Post-Town1",
        postcode: "A0 0AA",
      },
      assessor: { scheme_assessor_id: "SPEC000000", name: "Name0" },
      current_carbon_emission: 2.4,
      current_energy_efficiency_band: "e",
      current_energy_efficiency_rating: 50,
      dwelling_type: "Dwelling-Type0",
      estimated_energy_cost: "689.83",
      heat_demand: {
        current_space_heating_demand: 30.0,
        current_water_heating_demand: 60.0,
        impact_of_cavity_insulation: -12,
        impact_of_loft_insulation: -8,
        impact_of_solid_wall_insulation: -16,
      },
      heating_cost_current: "365.98",
      heating_cost_potential: "250.34",
      hot_water_cost_current: "200.40",
      hot_water_cost_potential: "180.43",
      lighting_cost_current: "123.45",
      lighting_cost_potential: "84.23",
      potential_carbon_emission: 1.4,
      potential_energy_efficiency_band: "e",
      potential_energy_efficiency_rating: 50,
      potential_energy_saving: "174.83",
      property_age_band: "K",
      property_summary: [
        {
          description: "Description0",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "wall",
        },
        {
          description: "Description1",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "wall",
        },
        {
          description: "Description2",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "roof",
        },
        {
          description: "Description3",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "roof",
        },
        {
          description: "Description4",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "floor",
        },
        {
          description: "Description5",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "floor",
        },
        {
          description: "Description6",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "window",
        },
        {
          description: "Description7",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "main_heating",
        },
        {
          description: "Description8",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "main_heating",
        },
        {
          description: "Description9",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "main_heating_controls",
        },
        {
          description: "Description10",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "main_heating_controls",
        },
        {
          description: "Description11",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "hot_water",
        },
        {
          description: "Description12",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "lighting",
        },
        {
          description: "Description13",
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "secondary_heating",
        },
      ],
      recommended_improvements: [
        {
          energy_performance_rating_improvement: 50,
          environmental_impact_rating_improvement: 50,
          green_deal_category_code: "1",
          improvement_category: "6",
          improvement_code: "5",
          improvement_description: nil,
          improvement_title: nil,
          improvement_type: "Z3",
          indicative_cost: "5",
          sequence: 0,
          typical_saving: "0.0",
        },
        {
          energy_performance_rating_improvement: 60,
          environmental_impact_rating_improvement: 64,
          green_deal_category_code: "3",
          improvement_category: "2",
          improvement_code: "1",
          improvement_description: nil,
          improvement_title: nil,
          improvement_type: "Z2",
          indicative_cost: "2",
          sequence: 1,
          typical_saving: "0.1",
        },
      ],
      related_party_disclosure_number: nil,
      related_party_disclosure_text: "Related-Party-Disclosure-Text0",
      tenure: "1",
      total_floor_area: 0.0,
      opt_out: false,
      status: "ENTERED",
    }.freeze

  it "should read the appropriate values from the XML doc" do
    test_xml_doc(supported_schema, asserted_keys)
  end

  it "returns the expect error without a valid schema type" do
    expect {
      ViewModel::RdSapWrapper.new "", "invalid"
    }.to raise_error.with_message "Unsupported schema type"
  end
end
