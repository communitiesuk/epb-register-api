VALID_ASSESSOR_REQUEST_BODY = {
  firstName: "Someone",
  middleNames: "Muddle",
  lastName: "Person",
  dateOfBirth: "1991-02-25",
  searchResultsComparisonPostcode: "",
  qualifications: { domesticRdSap: "ACTIVE" },
  contactDetails: {
    telephoneNumber: "010199991010101", email: "person@person.com"
  },
}.freeze

class Samples


  def self.xml(schema, type = "epc")
    path = File.join Dir.pwd, "spec/fixtures/samples/#{schema}/#{type}.xml"

    unless File.exist? path
      raise ArgumentError,
            "No #{type} sample found for schema #{schema}, create one at #{
              path
            }"
    end

    File.read path
  end

  def self.update_test_hash(test_hash, args = {})
    hash = test_hash
    hash.merge!(args)
  end

  module ViewModels

    def self.NI_PostCode
      "BT0 0AA"
    end

    def self.Lprn_code
      "LPRN-000000000001"
    end

    module Dec
      def self.supported_schema
        [
          {
            schema_name: "CEPC-8.0.0",
            xml: Samples.xml("CEPC-8.0.0", "dec-large-building"),
            unsupported_fields: [],
            different_fields: {
              date_of_expiry: "2020-12-31",
              technical_information: {
                main_heating_fuel: "Natural Gas",
                building_environment: "Heating and Natural Ventilation",
                floor_area: "9000",
                asset_rating: "100",
                occupier: "Primary School",
                annual_energy_use_fuel_thermal: "1",
                annual_energy_use_electrical: "1",
                typical_thermal_use: "1",
                typical_electrical_use: "1",
                renewables_fuel_thermal: "1",
                renewables_electrical: "1",
              },
            },
          },
          {
            schema_name: "CEPC-NI-8.0.0",
            xml: Samples.xml("CEPC-NI-8.0.0", "dec"),
            unsupported_fields: [],
            different_fields: { date_of_expiry: "2020-12-31" },
            different_buried_fields: { address: { postcode: ni_postcode } },
          },

          {
            schema_name: "CEPC-7.1",
            xml: Samples.xml("CEPC-7.1", "dec-ni"),
            unsupported_fields: [],
            different_fields: { date_of_expiry: "2020-12-31" },
            different_buried_fields: {
              address: { address_id: lprn, postcode: ni_postcode },
            },
          },

          {
            schema_name: "CEPC-7.0",
            xml: Samples.xml("CEPC-7.0", "dec-ni"),
            unsupported_fields: [],
            different_fields: { date_of_expiry: "2020-12-31" },
            different_buried_fields: {
              address: { address_id: lprn, postcode: ni_postcode },
            },
          },
          {
            schema_name: "CEPC-6.0",
            xml: Samples.xml("CEPC-6.0", "dec-ni"),
            unsupported_fields: [],
            different_fields: { date_of_expiry: "2020-12-31" },
            different_buried_fields: {
              address: { address_id: lprn, postcode: ni_postcode },
            },
          },
          {
            schema_name: "CEPC-5.0",
            xml: Samples.xml("CEPC-5.0", "dec-ni"),
            unsupported_fields: [],
            different_fields: { date_of_expiry: "2020-12-31" },
            different_buried_fields: {
              address: { address_id: lprn, postcode: ni_postcode },
            },
          },

          {
            schema_name: "CEPC-4.0",
            xml: Samples.xml("CEPC-4.0", "dec-ni"),
            unsupported_fields: [],
            different_fields: { date_of_expiry: "2020-12-31" },
            different_buried_fields: {
              address: { address_id: lprn, postcode: ni_postcode },
            },
          },

          {
            schema_name: "CEPC-3.1",
            xml: Samples.xml("CEPC-3.1", "dec-ni"),
            unsupported_fields: [],
            different_fields: { date_of_expiry: "2020-12-31" },
            different_buried_fields: {
              address: { address_id: lprn, postcode: ni_postcode },
            },
          },
        ]

      end

      def self.get_schema(name, xml, different_fields={}, different_buried_fields={})
        merged_different_fields = different_fields.merge(different_buried_fields)
        {
          schema_name: name,
          xml: xml,
          unsupported_fields: [],
          different_fields: merged_different_fields,
          different_buried_fields: {},
        }
      end


      def self.report_test_hash
        {
          rrn: "0000-0000-0000-0000-0000",
          building_reference_number: "UPRN-000000000001",
          address1: "2 Lonely Street",
          address2: nil,
          address3: nil,
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
          lodgement_date: "",
          lodgement_datetime: "",
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
          ac_inpsection_commissioned: "1",
          building_environment: "Heating and Natural Ventilation",
          building_category: "C1",
          report_type: "1",


        }
      end

      def self.update_schema_for_report
        schema = self.supported_schema
        report_schema = [] # new hash to hold schema
        # loop over existing schema
        schema.each do  |index|
          different_fields = index[:different_fields]
          # check schemas and update different fields based on their types
          if !index[:schema_name].include?("8")
            different_fields[:building_reference_number]  = Samples::ViewModels.Lprn_code
          end

          if index[:schema_name].include?("CEPC-8")
            different_fields = { date_of_expiry: index[:different_fields][:date_of_expiry], }
            different_fields.merge(index[:different_fields][:technical_information])
            different_fields[:total_floor_area]= "9000"

          end

          if index[:schema_name].include?("4.0")
            different_fields[:aircon_present] = "Y"
          end

          if index[:schema_name].include?("3.1")
            different_fields[:postcode] = ""
            different_fields[:aircon_present] = "N"
            different_fields[:aircon_kw_rating] = nil
            different_fields[:ac_inpsection_commissioned] = nil
            different_fields[:occupancy_level] = "Extended Occupancy"
          end

          if index[:different_buried_fields]
            if index[:different_buried_fields][:address]
              different_fields[:postcode] = index[:different_buried_fields][:address][:postcode]
            end
          end
          # set hash into return array
          report_schema << get_schema(index[:schema_name], index[:xml], different_fields,)
        end

        report_schema
      end
    end


    module Cepc

      def self.supported_schema
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

      def self.report_test_hash
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

      def self.different_fields
        {
          building_reference_number:  Samples::ViewModels.Lprn_code,
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


      def self.update_schema_for_report(schema)

        schema.select { |hash|  !hash[:schema_name].include?("8") }
              .map { |selected_hash|
                selected_hash[:different_fields][:building_reference_number] =Samples::ViewModels.Lprn_code
              }

        schema.select { |hash|  hash[:schema_name].include?("5") }
              .map { |selected_hash|
                selected_hash[:different_fields] =
                  {
                    building_reference_number: Samples::ViewModels.Lprn_code,
                    standard_emissions: nil,
                    primary_energy: nil,
                  }
              }

        schema.select { |hash|  hash[:schema_name].include?("4") }
              .map { |selected_hash|
                selected_hash[:different_fields] =
                  different_fields
              }


        schema3_extra_different_fields = {
          other_fuel_description: nil,
          estimated_aircon_kw_rating: nil,
          ac_inpsection_commissioned: nil,
          aircon_kw_rating:nil,
        }

        schema.select { |hash|  hash[:schema_name].include?("3") }
              .map { |selected_hash|
                selected_hash[:different_fields] =  different_fields.merge(schema3_extra_different_fields)
              }


      end


    end


  end

end
