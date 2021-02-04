VALID_ASSESSOR_REQUEST_BODY = {
  firstName: "Someone",
  middleNames: "Muddle",
  lastName: "Person",
  dateOfBirth: "1991-02-25",
  searchResultsComparisonPostcode: "",
  qualifications: {
    domesticRdSap: "ACTIVE",
  },
  contactDetails: {
    telephoneNumber: "010199991010101",
    email: "person@person.com",
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
    hash = test_hash.dup
    hash.merge!(args)
  end

  # TODO: move to separate file and define as Mixin
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
            schema_type: "dec-large-building",
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
            schema_type: "dec",
            xml: Samples.xml("CEPC-NI-8.0.0", "dec"),
            unsupported_fields: [],
            different_fields: {
              date_of_expiry: "2020-12-31",
            },
            different_buried_fields: {
              address: {
                postcode: Samples::ViewModels.NI_PostCode,
              },
            },
          },
          {
            schema_name: "CEPC-7.1",
            schema_type: "dec-ni",
            xml: Samples.xml("CEPC-7.1", "dec-ni"),
            unsupported_fields: [],
            different_fields: {
              date_of_expiry: "2020-12-31",
            },
            different_buried_fields: {
              address: {
                address_id: Samples::ViewModels.Lprn_code,
                postcode: Samples::ViewModels.NI_PostCode,
              },
            },
          },
          {
            schema_name: "CEPC-7.0",
            schema_type: "dec-ni",
            xml: Samples.xml("CEPC-7.0", "dec-ni"),
            unsupported_fields: [],
            different_fields: {
              date_of_expiry: "2020-12-31",
            },
            different_buried_fields: {
              address: {
                address_id: Samples::ViewModels.Lprn_code,
                postcode: Samples::ViewModels.NI_PostCode,
              },
            },
          },
          {
            schema_name: "CEPC-6.0",
            schema_type: "dec-ni",
            xml: Samples.xml("CEPC-6.0", "dec-ni"),
            unsupported_fields: [],
            different_fields: {
              date_of_expiry: "2020-12-31",
            },
            different_buried_fields: {
              address: {
                address_id: Samples::ViewModels.Lprn_code,
                postcode: Samples::ViewModels.NI_PostCode,
              },
            },
          },
          {
            schema_name: "CEPC-5.1",
            schema_type: "dec-ni",
            xml: Samples.xml("CEPC-5.1", "dec-ni"),
            unsupported_fields: [],
            different_fields: {
              date_of_expiry: "2020-12-31",
            },
            different_buried_fields: {
              address: {
                address_id: Samples::ViewModels.Lprn_code,
                postcode: Samples::ViewModels.NI_PostCode,
              },
            },
          },
          {
            schema_name: "CEPC-5.0",
            schema_type: "dec-ni",
            xml: Samples.xml("CEPC-5.0", "dec-ni"),
            unsupported_fields: [],
            different_fields: {
              date_of_expiry: "2020-12-31",
            },
            different_buried_fields: {
              address: {
                address_id: Samples::ViewModels.Lprn_code,
                postcode: Samples::ViewModels.NI_PostCode,
              },
            },
          },
          {
            schema_name: "CEPC-4.0",
            schema_type: "dec-ni",
            xml: Samples.xml("CEPC-4.0", "dec-ni"),
            unsupported_fields: [],
            different_fields: {
              date_of_expiry: "2020-12-31",
            },
            different_buried_fields: {
              address: {
                address_id: Samples::ViewModels.Lprn_code,
                postcode: Samples::ViewModels.NI_PostCode,
              },
            },
          },
          {
            schema_name: "CEPC-3.1",
            schema_type: "dec-ni",
            xml: Samples.xml("CEPC-3.1", "dec-ni"),
            unsupported_fields: [],
            different_fields: {
              date_of_expiry: "2020-12-31",
            },
            different_buried_fields: {
              address: {
                address_id: Samples::ViewModels.Lprn_code,
                postcode: Samples::ViewModels.NI_PostCode,
              },
            },
          },
        ]
      end

      def self.get_schema(
        name,
        type,
        xml,
        different_fields = {},
        different_buried_fields = {}
      )
        merged_different_fields =
          different_fields.merge(different_buried_fields)
        {
          schema_name: name,
          schema_type: type,
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
          ac_inpsection_commissioned: "1",
          building_environment: "Heating and Natural Ventilation",
          building_category: "C1",
          report_type: "1",
        }
      end

      def self.test_keys
        Samples::ViewModels::Dec.report_test_hash.keys
      end

      def self.update_schema_for_report
        schema = supported_schema
        report_schema = [] # new hash to hold schema

        # loop over existing schema
        schema.each do |index|
          different_fields = index[:different_fields]

          # check schemas and update different fields based on their types
          unless index[:schema_name].include?("8")
            different_fields[:building_reference_number] =
              Samples::ViewModels.Lprn_code
          end

          if index[:schema_name].include?("CEPC-8")
            different_fields = {
              date_of_expiry: index[:different_fields][:date_of_expiry],
            }
            different_fields.merge(
              index[:different_fields][:technical_information],
            )
            different_fields[:total_floor_area] = "9000"
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
              different_fields[:postcode] =
                index[:different_buried_fields][:address][:postcode]
            end
          end

          # set hash into return array
          report_schema <<
            get_schema(
              index[:schema_name],
              index[:schema_type],
              index[:xml],
              different_fields,
            )
        end

        report_schema
      end
    end

    module RdSap
      def self.supported_schema
        [
          {
            schema_name: "RdSAP-Schema-20.0.0",
            xml: Samples.xml("RdSAP-Schema-20.0.0"),
            unsupported_fields: [],
            different_fields: {},
          },
          {
            schema_name: "RdSAP-Schema-19.0",
            xml: Samples.xml("RdSAP-Schema-19.0"),
            unsupported_fields: [],
            different_fields: {},
            different_buried_fields: {
              address: {
                address_id: "LPRN-0000000000",
              },
            },
          },
          {
            schema_name: "RdSAP-Schema-18.0",
            xml: Samples.xml("RdSAP-Schema-18.0"),
            unsupported_fields: [],
            different_fields: {},
            different_buried_fields: {
              address: {
                address_id: "LPRN-0000000000",
              },
            },
          },
          {
            schema_name: "RdSAP-Schema-17.1",
            xml: Samples.xml("RdSAP-Schema-17.1"),
            unsupported_fields: [],
            different_fields: {},
            different_buried_fields: {
              address: {
                address_id: "LPRN-0000000000",
              },
            },
          },
          {
            schema_name: "RdSAP-Schema-17.0",
            xml: Samples.xml("RdSAP-Schema-17.0"),
            unsupported_fields: [],
            different_fields: {},
            different_buried_fields: {
              address: {
                address_id: "LPRN-0000000000",
              },
            },
          },
          {
            schema_name: "RdSAP-Schema-NI-20.0.0",
            xml: Samples.xml("RdSAP-Schema-NI-20.0.0"),
            unsupported_fields: [],
            different_fields: {},
          },
          {
            schema_name: "RdSAP-Schema-NI-19.0",
            xml: Samples.xml("RdSAP-Schema-NI-19.0"),
            unsupported_fields: [],
            different_fields: {},
            different_buried_fields: {
              address: {
                address_id: "LPRN-0000000000",
              },
            },
          },
          {
            schema_name: "RdSAP-Schema-NI-18.0",
            xml: Samples.xml("RdSAP-Schema-NI-18.0"),
            unsupported_fields: [],
            different_fields: {},
            different_buried_fields: {
              address: {
                address_id: "LPRN-0000000000",
              },
            },
          },
          {
            schema_name: "RdSAP-Schema-NI-17.4",
            xml: Samples.xml("RdSAP-Schema-NI-17.4"),
            unsupported_fields: [],
            different_fields: {},
            different_buried_fields: {
              address: {
                address_id: "LPRN-0000000000",
              },
            },
          },
          {
            schema_name: "RdSAP-Schema-NI-17.3",
            xml: Samples.xml("RdSAP-Schema-NI-17.3"),
            unsupported_fields: [],
            different_fields: {},
            different_buried_fields: {
              address: {
                address_id: "LPRN-0000000000",
              },
            },
          },
        ].freeze
      end

      def self.get_schema(
        name,
        type,
        xml,
        different_fields = {},
        different_buried_fields = {}
      )
        merged_different_fields =
          different_fields.merge(different_buried_fields)
        {
          schema_name: name,
          schema_type: type,
          xml: xml,
          unsupported_fields: [],
          different_fields: merged_different_fields,
          different_buried_fields: {},
        }
      end

      def self.update_schema_for_report
        schema = supported_schema
        report_schema = [] # new hash to hold schema

        # loop over existing schema
        schema.each do |index|
          different_fields = index[:different_fields]

          # check schemas and update different fields based on their types
          unless index[:schema_name].include?("20")
            different_fields = { building_reference_number: "LPRN-0000000000" }
          end

          # set hash into return array
          report_schema <<
            get_schema(
              index[:schema_name],
              index[:schema_type],
              index[:xml],
              different_fields,
            )
        end

        report_schema
      end

      def self.report_test_hash
          {
            rrn: "0000-0000-0000-0000-0000",
            inspection_date: "2020-05-04",
            lodgement_date: "2020-05-04",
            building_reference_number: "UPRN-000000000000",
            address1: "1 Some Street",
            address2: "",
            address3: "",
            posttown: "Post-Town1",
            postcode: "A0 0AA",
            construction_age_band: "K",
            current_energy_rating: "e",
            potential_energy_rating: "e",
            current_energy_efficiency: "50",
            potential_energy_efficiency: "50",
            property_type: "Dwelling-Type0",
            tenure: "1",
            transaction_type: "1",
            environmental_impact_current: "50",
            environmental_impact_potential: "50",
            energy_consumption_current: "0",
            energy_consumption_potential: "0",
            co2_emissions_current: "2.4",
            co2_emiss_curr_per_floor_area: "0",
            co2_emissions_potential: "1.4",
            heating_cost_current: "365.98",
            heating_cost_potential: "250.34",
            hot_water_cost_current: "200.40",
            hot_water_cost_potential: "180.43",
            lighting_cost_current: "123.45",
            lighting_cost_potential: "84.23",
            total_floor_area: "1",
            mains_gas_flag: "Y",
            flat_top_storey: "N",
            flat_storey_count: "3",
            main_heating_controls: "Description9",
            multi_glaze_proportion: "100",
            glazed_area: "1",
            number_habitable_rooms: "5",
            number_heated_rooms: "5",
            low_energy_lighting: "100",
            fixed_lighting_outlets_count: "16",
            low_energy_fixed_lighting_outlets_count: "16",
            number_open_fireplaces: "0",
            hotwater_description: "Description11",
            hot_water_energy_eff: "N/A",
            hot_water_env_eff: "N/A",
            wind_turbine_count: "0",
            heat_loss_corridor: "2",
            unheated_corridor_length: "10",
            windows_description: "Description6",
            windows_energy_eff: "N/A",
            windows_env_eff: "N/A",
            secondheat_description: "Description13",
            sheating_energy_eff: "N/A",
            sheating_env_eff: "N/A",
            lighting_description: "Description12",
            lighting_energy_eff: "N/A",
            lighting_env_eff: "N/A",
            photo_supply: "0",
            built_form: "Semi-Detached",
            mainheat_description: "Description7, Description8",
            mainheat_energy_eff: "N/A",
            mainheat_env_eff: "N/A",
            extension_count: "0",
            report_type: "2",
            mainheatcont_description: "Description9, Description10",
            roof_description: "Description2, Description3",
            roof_energy_eff: "N/A, N/A",
            roof_env_eff: "N/A, N/A",
            walls_description: "Description0, Description1",
            walls_energy_eff: "N/A, N/A",
            walls_env_eff: "N/A, N/A",
            energy_tariff: "2",
            floor_level: "01",
            solar_water_heating_flag: "N",
            mechanical_ventilation: "0",
            floor_height: "2.45"
          }
      end
    end

    module Sap

      def self.report_test_hash
        {
          rrn: "0000-0000-0000-0000-0000",
          inspection_date: "2020-05-04",
          lodgement_date: "2020-05-04",
          building_reference_number: "UPRN-000000000000",
          address1: "1 Some Street",
          address2: "",
          address3: "",
          posttown: "Post-Town1",
          postcode: "A0 0AA",
          construction_age_band: "1750",
          current_energy_rating: "e",
          potential_energy_rating: "e",
          current_energy_efficiency: "50",
          potential_energy_efficiency: "50",
          property_type: "Dwelling-Type0",
          tenure: "1",
          transaction_type: "1",
          environmental_impact_current: "50",
          environmental_impact_potential: "50",
          energy_consumption_current: "0",
          energy_consumption_potential: "0",
          co2_emissions_current: "2.4",
          co2_emiss_curr_per_floor_area: "0",
          co2_emissions_potential: "1.4",
          heating_cost_current: "365.98",
          heating_cost_potential: "250.34",
          hot_water_cost_current: "200.40",
          hot_water_cost_potential: "180.43",
          lighting_cost_current: "123.45",
          lighting_cost_potential: "84.23",
          total_floor_area: "10",
          mains_gas_flag: nil,
          flat_top_storey: "N",
          flat_storey_count: nil,
          multi_glaze_proportion: "50",
          glazed_area: nil,
          number_habitable_rooms: nil,
          number_heated_rooms: nil,
          low_energy_lighting: "100",
          fixed_lighting_outlets_count: "8",
          low_energy_fixed_lighting_outlets_count: "8",
          number_open_fireplaces: "0",
          hotwater_description: "Gas boiler",
          hot_water_energy_eff: "N/A",
          hot_water_env_eff: "N/A",
          wind_turbine_count: "0",
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
          mainheat_description: "Thermostat, Thermostat",
        }
      end
    end
  end
end
