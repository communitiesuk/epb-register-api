



def different_fields
  {
    building_reference_number: lprn_test_value,
    transaction_type: nil,
    target_emissions: nil,
    typical_emissions: nil,
    building_emission_rate: nil,
    building_emission: nil,
    standard_emissions: nil,
    building_emissions:nil,
    primary_energy: nil,

  }
end

def different_fields_spec_3
  my_hash = different_fields
  my_hash[:other_fuel_description] = nil
  my_hash[:aircon_kw_rating] = nil
  my_hash[:estimated_aircon_kw_rating] = nil
  my_hash[:ac_inpsection_commissioned] = nil
  my_hash
end

def update_schema_for_report(schema)

  schema.select { |hash|  !hash[:schema_name].include?("8") }
        .map { |selected_hash|
          selected_hash[:different_fields][:building_reference_number] =lprn_test_value
        }

  schema.select { |hash|  hash[:schema_name].include?("5") }
        .map { |selected_hash|
          selected_hash[:different_fields] =
            {
              building_reference_number: lprn_test_value,
              standard_emissions: nil,
              primary_energy: nil,
            }
        }

  schema.select { |hash|  hash[:schema_name].include?("4") }
        .map { |selected_hash|
          selected_hash[:different_fields] =
            different_fields
        }

  schema.select { |hash|  hash[:schema_name].include?("3") }
        .map { |selected_hash|
          selected_hash[:different_fields] = different_fields_spec_3
        }


end

def report_test_hash
  {
    rrn: "0000-0000-0000-0000-0000",
    address1: "2 Lonely Street",
    address2: nil,
    address3: nil,
    address4: nil,
    posttown: "Post-Town1",
    postcode: "A0 0AA",
    building_reference_number: "UPRN-000000000001",
    asset_rating: "80",
    asset_rating_band: "d",
    property_type: "B1 Offices and Workshop businesses",
    inspection_date: "2020-05-04",
    lodgement_date: "2020-05-04",
    transaction_type: "1",
    new_build_benchmark: "28",
    existing_stock_benchmark: "81",
    standard_emissions: "42.07",
    building_emissions: "67.09",
    main_heating_fuel: "Natural Gas",
    building_level: "3",
    floor_area: "403",
    other_fuel_description: "Test",
    special_energy_uses: "Test sp",
    aircon_present: "N",
    aircon_kw_rating: "100",
    estimated_aircon_kw_rating: "3",
    ac_inpsection_commissioned: "1",
    target_emissions: "23.2",
    typical_emissions: "67.98",
    building_environment: "Air Conditioning",
    primary_energy: "413.22",
    report_type: "3",
  }
end







