def test_xml_doc(supported_schema, asserted_keys, test_report = false)
  supported_schema.each do |schema|
    view_model = ViewModel::Factory.new.create(schema[:xml], schema[:schema_name], nil)
    # test either to has or to report
    view_model = test_report ? view_model.to_report : view_model.to_hash


    asserted_keys.each do |key, value|
      result = view_model[key]

      if schema.key?(:different_buried_fields) &&
          schema[:different_buried_fields].key?(key)
        value = value.merge(schema[:different_buried_fields][key])
      end

      if schema[:unsupported_fields].include? key
        expect(result).to be_nil,
                          "Failed on #{schema[:schema_name]}:#{key}\n" \
                            "Unsupported fields must return nil, got \"#{result}\""
      elsif schema[:different_fields].key? key
        expect(result).to eq(schema[:different_fields][key]),
                          "Failed on #{schema[:schema_name]}:#{key}\n with different value" \
                            "EXPECTED: \"#{schema[:different_fields][key]}\"\n" \
                            "     GOT: \"#{result}\"\n"
      else
        expect(result).to eq(value),
                          "Failed on #{schema[:schema_name]}:#{key}\n" \
                            "EXPECTED: \"#{value}\"\n" \
                            "     GOT: \"#{result}\"\n"
      end
    end
  end
end

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



def lprn_test_value
  "LPRN-000000000001"
end

def uprn_test_value
  lprn_test_value.gsub('LPRN', "UPRN")
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
