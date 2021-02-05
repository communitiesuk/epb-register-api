require_relative "xml_view_test_helper"

describe ViewModel::DecWrapper do
  context "when calling to_hash" do
    let(:schemas) do
      [
        {
          schema: "CEPC-8.0.0",
          type: "dec-large-building",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
          different_buried_fields: {
            technical_information: {
              floor_area: "9000",
            },
          },
        },
        {
          schema: "CEPC-NI-8.0.0",
          type: "dec",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
          different_buried_fields: {
            address: {
              postcode: "BT0 0AA",
            },
          },
        },
        {
          schema: "CEPC-7.1",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
          different_buried_fields: {
            address: {
              address_id: "LPRN-000000000001",
              postcode: "BT0 0AA",
            },
          },
        },
        {
          schema: "CEPC-7.0",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
          different_buried_fields: {
            address: {
              address_id: "LPRN-000000000001",
              postcode: "BT0 0AA",
            },
          },
        },
        {
          schema: "CEPC-6.0",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
          different_buried_fields: {
            address: {
              address_id: "LPRN-000000000001",
              postcode: "BT0 0AA",
            },
          },
        },
        {
          schema: "CEPC-5.1",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
          different_buried_fields: {
            address: {
              address_id: "LPRN-000000000001",
              postcode: "BT0 0AA",
            },
          },
        },
        {
          schema: "CEPC-5.0",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
          different_buried_fields: {
            address: {
              address_id: "LPRN-000000000001",
              postcode: "BT0 0AA",
            },
          },
        },
        {
          schema: "CEPC-4.0",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
          different_buried_fields: {
            address: {
              address_id: "LPRN-000000000001",
              postcode: "BT0 0AA",
            },
          },
        },
        {
          schema: "CEPC-3.1",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
          different_buried_fields: {
            address: {
              address_id: "LPRN-000000000001",
              postcode: "BT0 0AA",
            },
          },
        },
      ]
    end

    let(:assertion) do
      {
        assessment_id: "0000-0000-0000-0000-0000",
        date_of_expiry: "2029-12-31",
        date_of_registration: "2020-05-04",
        address: {
          address_id: "UPRN-000000000001",
          address_line1: "Some Unit",
          address_line2: "2 Lonely Street",
          address_line3: "Some Area",
          address_line4: "Some County",
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
          contact_details: {
            email: "a@b.c",
            telephone: "0921-19037",
          },
        },
      }
    end

    it "reads the appropriate values" do
      test_xml_doc(schemas, assertion)
    end
  end

  context "when calling to_report" do
    let(:schemas) do
      [
        {
          schema: "CEPC-8.0.0",
          type: "dec-large-building",
          different_fields: {
            date_of_expiry: "2020-12-31",
            total_floor_area: "9000",
            building_reference_number: "UPRN-000000000001",
          },
        },
        {
          schema: "CEPC-8.0.0",
          type: "dec",
          different_fields: {
            date_of_expiry: "2020-12-31",
            building_reference_number: "UPRN-000000000001",
          },
        },
        {
          schema: "CEPC-NI-8.0.0",
          type: "dec",
          different_fields: {
            date_of_expiry: "2020-12-31",
            postcode: "BT0 0AA",
            building_reference_number: "UPRN-000000000001",
          },
        },
        {
          schema: "CEPC-7.1",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
            postcode: "BT0 0AA",
          },
        },
        {
          schema: "CEPC-7.0",
          type: "dec",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
        },
        {
          schema: "CEPC-7.0",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
            postcode: "BT0 0AA",
          },
        },
        {
          schema: "CEPC-6.0",
          type: "dec",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
        },
        {
          schema: "CEPC-6.0",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
            postcode: "BT0 0AA",
          },
        },
        {
          schema: "CEPC-5.1",
          type: "dec",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
        },
        {
          schema: "CEPC-5.1",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
            postcode: "BT0 0AA",
          },
        },
        {
          schema: "CEPC-5.0",
          type: "dec",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
        },
        {
          schema: "CEPC-5.0",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
            postcode: "BT0 0AA",
          },
        },
        {
          schema: "CEPC-4.0",
          type: "dec",
          different_fields: {
            date_of_expiry: "2020-12-31",
          },
        },
        {
          schema: "CEPC-4.0",
          type: "dec-ni",
          different_fields: {
            date_of_expiry: "2020-12-31",
            postcode: "BT0 0AA",
          },
        },
        {
          schema: "CEPC-3.1",
          type: "dec",
          unsupported_fields: %i[
            aircon_kw_rating
            ac_inspection_commissioned
          ],
          different_fields: {
            aircon_present: "N",
            date_of_expiry: "2020-12-31",
          },
        },
        {
          schema: "CEPC-3.1",
          type: "dec-ni",
          unsupported_fields: %i[
            aircon_kw_rating
            ac_inspection_commissioned
          ],
          different_fields: {
            aircon_present: "N",
            date_of_expiry: "2020-12-31",
            postcode: "BT0 0AA",
          },
        },
      ]
    end

    let(:assertion) do
      {
        rrn: "0000-0000-0000-0000-0000",
        building_reference_number: "LPRN-000000000001",
        address1: "Some Unit",
        address2: "2 Lonely Street",
        address3: "Some Area",
        posttown: "Post-Town1",
        postcode: "A0 0AA",
        current_operational_rating: "1",
        yr1_operational_rating: "24",
        yr2_operational_rating: "40",
        energy_efficiency_band: "A",
        electric_co2: "7",
        heating_co2: "3",
        renewables_co2: "0",
        property_type: "B1 Offices and Workshop businesses",
        inspection_date: "2020-05-04",
        nominated_date: "2020-01-01",
        or_assessment_end_date: "2020-05-01",
        lodgement_date: "2020-05-04",
        main_benchmark: "",
        main_heating_fuel: "Natural Gas",
        special_energy_uses: "special",
        renewable_sources: "1",
        total_floor_area: "99",
        occupancy_level: "level",
        typical_thermal_use: "1",
        annual_electrical_fuel_usage: "1",
        typical_electrical_fuel_usage: "1",
        renewables_fuel_thermal: "1",
        renewables_electrical: "1",
        yr1_electricity_co2: "10",
        yr2_electricity_co2: "15",
        yr1_heating_co2: "5",
        yr2_heating_co2: "10",
        yr1_renewables_co2: "1",
        yr2_renewables_co2: "2",
        aircon_present: "Y",
        aircon_kw_rating: "1",
        ac_inspection_commissioned: "1",
        building_environment: "Heating and Natural Ventilation",
        building_category: "C1",
        report_type: "1",
      }
    end

    it "reads the appropriate values" do
      test_xml_doc(schemas, assertion, :to_report)
    end
  end

  it "returns the expect error without a valid schema type" do
    expect {
      ViewModel::DecWrapper.new "", "invalid"
    }.to raise_error.with_message "Unsupported schema type"
  end
end
