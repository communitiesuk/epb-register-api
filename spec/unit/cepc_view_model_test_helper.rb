

def set_supported_schema
  [
    {
      schema_name: "CEPC-8.0.0",
      xml: Samples.xml("CEPC-8.0.0", "cepc"),
      unsupported_fields: [],
      different_fields: { related_rrn: nil },
    },
    {
      schema_name: "CEPC-NI-8.0.0",
      xml: Samples.xml("CEPC-NI-8.0.0", "cepc"),
      unsupported_fields: [],
      different_fields: {},
    },
    {
      schema_name: "CEPC-7.1",
      xml: Samples.xml("CEPC-7.1", "cepc"),
      unsupported_fields: [],
      different_fields: {},
      different_buried_fields: { address: { address_id: lprn_test_value } },
    },
    {
      schema_name: "CEPC-7.0",
      xml: Samples.xml("CEPC-7.0", "cepc"),
      unsupported_fields: %i[primary_energy_use],
      different_fields: {primary_energy: nil,},
      different_buried_fields: { address: { address_id: lprn_test_value } },
    },
    {
      schema_name: "CEPC-6.0",
      xml: Samples.xml("CEPC-6.0", "cepc"),
      unsupported_fields: %i[primary_energy_use],
      different_fields: { other_fuel_description: "Test", primary_energy: nil,},
      different_buried_fields: { address: { address_id: lprn_test_value }},
    },
    {
      schema_name: "CEPC-5.0",
      xml: Samples.xml("CEPC-5.0", "cepc"),
      unsupported_fields: %i[primary_energy_use],
      different_fields: { },
      different_buried_fields: { address: { address_id: lprn_test_value } },
    },
    {
      schema_name: "CEPC-4.0",
      xml: Samples.xml("CEPC-4.0", "cepc"),
      unsupported_fields: %i[primary_energy_use],
      different_fields: { building_emission_rate: nil, },
      different_buried_fields: { address: { address_id: lprn_test_value }  },
    },
    {
      schema_name: "CEPC-3.1",
      xml: Samples.xml("CEPC-3.1", "cepc"),
      unsupported_fields: %i[primary_energy_use],
      different_fields: { building_emission_rate: nil,  },
      different_buried_fields: { address: { address_id: lprn_test_value }  },
    },
  ]

end

def save_test_data
  scheme_id =  add_scheme_and_get_id
  @number_assments_to_test = 2
  non_domestic_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
  non_domestic_assessment_id = non_domestic_xml.at("//CEPC:RRN")
  non_domestic_assessment_date = non_domestic_xml.at("//CEPC:Registration-Date")

  add_assessor(
    scheme_id,
    "SPEC000000",
    AssessorStub.new.fetch_request_body(
      nonDomesticNos3: "ACTIVE",
      nonDomesticNos4: "ACTIVE",
      nonDomesticNos5: "ACTIVE",
      nonDomesticDec: "ACTIVE",
      domesticRdSap: "ACTIVE",
      domesticSap: "ACTIVE",
      nonDomesticSp3: "ACTIVE",
      nonDomesticCc4: "ACTIVE",
      gda: "ACTIVE",
      ),
    )

  non_domestic_assessment_date.children = "2020-05-04"
  lodged = lodge_assessment(
    assessment_body: non_domestic_xml.to_xml,
    accepted_responses: [201],
    auth_data: { scheme_ids: [scheme_id] },
    override: true,
    schema_name: "CEPC-8.0.0",
    )

  non_domestic_assessment_date.children = "2018-05-04"
  non_domestic_assessment_id.children = "0000-0000-0000-0000-0001"
  lodge_assessment(
    assessment_body: non_domestic_xml.to_xml,
    accepted_responses: [201],
    auth_data: { scheme_ids: [scheme_id] },
    override: true,
    schema_name: "CEPC-8.0.0",
    )

  open_data_export = described_class.new
  data = open_data_export.execute(
    { number_of_assessments: @number_assments_to_test, max_runs: "3", batch: "3" },
    )
end


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

def hash_to_test
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



def update_test_hash(args = {})
  hash = hash_to_test
  hash.merge!(args)
end



