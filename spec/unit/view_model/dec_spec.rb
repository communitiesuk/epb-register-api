require_relative "xml_view_test_helper"


describe ViewModel::DecWrapper do
  # You should only need to add to this list to test new CEPC schema
  supported_schema = Samples::ViewModels::Dec.supported_schema

  # You should only need to add to this list to test new fields on all CEPC schema
  asserted_keys = {
    assessment_id: "0000-0000-0000-0000-0000",
    date_of_expiry: "2029-12-31",
    date_of_registration: "2020-05-04",
    address: {
      address_id: "UPRN-000000000001",
      address_line1: "2 Lonely Street",
      address_line2: nil,
      address_line3: nil,
      address_line4: nil,
      town: "Post-Town1",
      postcode: "A0 0AA",
    },
    type_of_assessment: "DEC",
    report_type: "1",
    current_assessment: {
      date: "2020-01-01",
      energy_efficiency_rating: "1",
      energy_efficiency_band: "a",
      heating_co2: "3",
      electricity_co2: "7",
      renewables_co2: "0",
    },
    year1_assessment: {
      date: "2019-01-01",
      energy_efficiency_rating: "24",
      energy_efficiency_band: "a",
      heating_co2: "5",
      electricity_co2: "10",
      renewables_co2: "1",
    },
    year2_assessment: {
      date: "2018-01-01",
      energy_efficiency_rating: "40",
      energy_efficiency_band: "b",
      heating_co2: "10",
      electricity_co2: "15",
      renewables_co2: "2",
    },
    technical_information: {
      main_heating_fuel: "Natural Gas",
      building_environment: "Heating and Natural Ventilation",
      floor_area: "99",
      occupier: "Primary School",
      asset_rating: "100",
      annual_energy_use_fuel_thermal: "1",
      annual_energy_use_electrical: "1",
      typical_thermal_use: "1",
      typical_electrical_use: "1",
      renewables_fuel_thermal: "1",
      renewables_electrical: "1",
    },
    administrative_information: {
      issue_date: "2020-05-14",
      calculation_tool: "DCLG, ORCalc, v3.6.3",
      related_party_disclosure: "4",
      related_rrn: "4192-1535-8427-8844-6702",
    },
    assessor: {
      company_details: {
        address: "123 My Street, My City, AB3 4CD",
        name: "Joe Bloggs Ltd",
      },
      name: "Name1",
      scheme_assessor_id: "SPEC000000",
      contact_details: { email: "a@b.c", telephone: "0921-19037" },
    },
  }.freeze

  it "should read the appropriate values from the XML doc using the to_hash method" do
    test_xml_doc(supported_schema, asserted_keys)
  end

  it "should read the appropriate values from the XML doc using the to_report method" do
    test_xml_doc(
      Samples::ViewModels::Dec.update_schema_for_report,
      Samples::ViewModels::Dec.report_test_hash,
      true,
    )
  end

  it "returns the expect error without a valid schema type" do
    expect {
      ViewModel::DecWrapper.new "", "invalid"
    }.to raise_error.with_message "Unsupported schema type"
  end
end
