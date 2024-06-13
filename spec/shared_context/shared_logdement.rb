shared_context "when lodging XML" do
  include RSpecRegisterApiServiceMixin

  def add_assessor_helper
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id:,
      assessor_id: "SPEC000000",
      body: AssessorStub.new.fetch_request_body(
        non_domestic_nos3: "ACTIVE",
        non_domestic_nos4: "ACTIVE",
        non_domestic_nos5: "ACTIVE",
        non_domestic_dec: "ACTIVE",
        domestic_rd_sap: "ACTIVE",
        domestic_sap: "ACTIVE",
        non_domestic_sp3: "ACTIVE",
        non_domestic_cc4: "ACTIVE",
        gda: "ACTIVE",
      ),
    )
    scheme_id
  end

  def lodge_epc_helper(scheme_id:, schema:, rrn: nil, assessment_date: nil, uprn: nil, property_type: nil, override: false, postcode: nil)
    xml = Nokogiri.XML Samples.xml(schema)

    unless rrn.nil?
      assessment_id = xml.at("RRN")
      assessment_id.children = rrn
    end

    unless assessment_date.nil?
      registration_date = xml.at("Registration-Date")
      registration_date.children = assessment_date
    end

    unless uprn.nil?
      building_ref_number = xml.at("UPRN")
      building_ref_number.children = uprn
    end

    unless property_type.nil?
      property_type_node = xml.at("Property-Type")
      property_type_node.children = property_type
    end

    unless postcode.nil?
      postcode_node = xml.at("Property Address Postcode")
      postcode_node.children = postcode
    end

    lodge_assessment(
      assessment_body: xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      migrated: true,
      override:,
      schema_name: schema,
    )
  end

  def updated_created_at
    ActiveRecord::Base
      .connection.execute "UPDATE assessments SET created_at = '2017-05-04 00:00:00.000000' WHERE  assessment_id IN ('0000-0000-0000-0000-1010', '0000-0000-0000-0000-0100')"
  end

  def assert_errors(expected_errors:, values: nil, new_nodes: [], country_code: [:E])
    country_lookup = Domain::CountryLookup.new(country_codes: country_code)
    docs_under_test.each do |doc|
      xml_doc = Nokogiri.XML(Samples.xml(doc))

      values.each do |k, v|
        if v == :delete
          xml_doc.at(k).remove
        else
          xml_doc.at(k).children = v
        end
      end

      new_nodes.each do |node|
        xml_doc.at(node[:selector]).add_next_sibling(node[:xml])
      end

      wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, doc, false)
      adapter = wrapper.get_view_model
      errors = described_class.new.validate(adapter, country_lookup)
      expect(errors).to match_array(expected_errors)
    end
  end

  def expected_rdsap_values
    {
      assessment_id:
        "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
      inspection_date: "2020-05-04",
      lodgement_date: "2020-05-04",
      lodgement_datetime: "2020-05-04 00:00:00",
      building_reference_number: "UPRN-000000000000",
      address1: "1 Some Street",
      address2: "",
      address3: "",
      posttown: "Whitbury",
      postcode: "A0 0AA",
      construction_age_band: "England and Wales: 2007-2011",
      current_energy_rating: "e",
      potential_energy_rating: "c",
      current_energy_efficiency: 50,
      potential_energy_efficiency: 72,
      property_type: "House",
      tenure: "Owner-occupied",
      transaction_type: "marketed sale",
      environment_impact_current: 52,
      environment_impact_potential: 74,
      energy_consumption_current: "230",
      energy_consumption_potential: "88",
      co2_emissions_current: "2.4",
      co2_emiss_curr_per_floor_area: "20",
      co2_emissions_potential: "1.4",
      heating_cost_current: "365.98",
      heating_cost_potential: "250.34",
      hot_water_cost_current: "200.40",
      hot_water_cost_potential: "180.43",
      lighting_cost_current: "123.45",
      lighting_cost_potential: "84.23",
      total_floor_area: "55",
      mains_gas_flag: "Y",
      flat_top_storey: "N",
      flat_storey_count: 3,
      multi_glaze_proportion: "100",
      glazed_area: "Normal",
      number_habitable_rooms: 5,
      number_heated_rooms: 5,
      low_energy_lighting: "100",
      fixed_lighting_outlets_count: 16,
      low_energy_fixed_lighting_outlets_count: 16,
      number_open_fireplaces: 0,
      hotwater_description: "From main system",
      hot_water_energy_eff: "Good",
      hot_water_env_eff: "Good",
      wind_turbine_count: 0,
      heat_loss_corridor: "unheated corridor",
      unheated_corridor_length: "10",
      windows_description: "Fully double glazed",
      windows_energy_eff: "Average",
      windows_env_eff: "Average",
      secondheat_description: "Room heaters, electric",
      sheating_energy_eff: "N/A",
      sheating_env_eff: "N/A",
      lighting_description: "Low energy lighting in 50% of fixed outlets",
      lighting_energy_eff: "Good",
      lighting_env_eff: "Good",
      photo_supply: "0",
      built_form: "Semi-Detached",
      mainheat_description:
        "Boiler and radiators, anthracite, Boiler and radiators, mains gas",
      mainheat_energy_eff: "Average",
      mainheat_env_eff: "Very Poor",
      extension_count: 0,
      report_type: "2",
      mainheatcont_description: "Programmer, room thermostat and TRVs",
      roof_description: "Pitched, 25 mm loft insulation",
      roof_energy_eff: "Poor",
      roof_env_eff: "Poor",
      walls_description: "Solid brick, as built, no insulation (assumed)",
      walls_energy_eff: "Very Poor",
      walls_env_eff: "Very Poor",
      energy_tariff: "Single",
      floor_level: "01",
      solar_water_heating_flag: "N",
      mechanical_ventilation: "natural",
      floor_height: "2.45",
      main_fuel: "mains gas (not community)",
      floor_description: "Suspended, no insulation (assumed)",
      floor_energy_eff: "N/A",
      floor_env_eff: "N/A",
      mainheatc_energy_eff: "Good",
      mainheatc_env_eff: "Good",
      glazed_type: "double glazing installed during or after 2002",
      region: "London",
      country: "England",
    }
  end

  def expected_sap_values
    {
      assessment_id:
        "a154b93d62db9b77c82f6b11ba4a4a4056816572180c95e0bc5d486b905d4996",
      inspection_date: "2020-05-04",
      lodgement_date: "2020-05-04",
      lodgement_datetime: "2020-05-04 00:00:00",
      building_reference_number: "UPRN-000000000000",
      address1: "1 Some Street",
      address2: "Some Area",
      address3: "Some County",
      posttown: "Whitbury",
      postcode: "A0 0AA",
      construction_age_band: "1750",
      current_energy_rating: "e",
      potential_energy_rating: "c",
      current_energy_efficiency: 50,
      potential_energy_efficiency: 72,
      property_type: "Maisonette",
      tenure: "Owner-occupied",
      transaction_type: "marketed sale",
      environment_impact_current: 52,
      environment_impact_potential: 74,
      energy_consumption_current: "230",
      energy_consumption_potential: "88",
      co2_emissions_current: "2.4",
      co2_emiss_curr_per_floor_area: "20",
      co2_emissions_potential: "1.4",
      heating_cost_current: "365.98",
      heating_cost_potential: "250.34",
      hot_water_cost_current: "200.40",
      hot_water_cost_potential: "180.43",
      lighting_cost_current: "123.45",
      lighting_cost_potential: "84.23",
      total_floor_area: "69",
      mains_gas_flag: nil,
      flat_top_storey: "N",
      flat_storey_count: nil,
      multi_glaze_proportion: "50",
      glazed_area: nil,
      number_habitable_rooms: nil,
      number_heated_rooms: nil,
      low_energy_lighting: "100",
      fixed_lighting_outlets_count: 8,
      low_energy_fixed_lighting_outlets_count: 8,
      number_open_fireplaces: 0,
      hotwater_description: "Gas boiler",
      hot_water_energy_eff: "N/A",
      hot_water_env_eff: "N/A",
      wind_turbine_count: 0,
      heat_loss_corridor: nil,
      unheated_corridor_length: nil,
      windows_description: "Glass window",
      windows_energy_eff: "N/A",
      windows_env_eff: "N/A",
      secondheat_description: "Electric heater",
      sheating_energy_eff: "N/A",
      sheating_env_eff: "N/A",
      lighting_description: "Energy saving bulbs",
      lighting_energy_eff: "N/A",
      lighting_env_eff: "N/A",
      photo_supply: nil,
      built_form: "Detached",
      mainheat_description: "Gas boiler, Gas boiler",
      report_type: "3",
      mainheatcont_description: "Thermostat",
      roof_description: "Slate roof",
      roof_energy_eff: "N/A",
      roof_env_eff: "N/A",
      walls_description: "Brick walls",
      walls_energy_eff: "N/A",
      walls_env_eff: "N/A",
      energy_tariff: "standard tariff",
      floor_level: "1",
      mainheat_energy_eff: "N/A",
      mainheat_env_eff: "N/A",
      extension_count: 0,
      solar_water_heating_flag: nil,
      mechanical_ventilation: "natural",
      floor_height: "2.4",
      main_fuel: "Electricity: electricity sold to grid",
      floor_description: "Tiled floor",
      floor_energy_eff: "N/A",
      floor_env_eff: "N/A",
      mainheatc_energy_eff: "N/A",
      mainheatc_env_eff: "N/A",
      glazed_type: nil,
      region: "London",
      country: "England",
    }
  end
end
