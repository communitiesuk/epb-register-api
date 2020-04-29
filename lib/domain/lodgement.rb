# frozen_string_literal: true

module Domain
  class Lodgement
    SCHEMAS = {
      'RdSAP-Schema-19.0': {
        report_type: 'RdSAP',
        schema_path:
          'api/schemas/xml/RdSAP-Schema-19.0/RdSAP/Templates/RdSAP-Report.xsd',
        data: {
          report_header: { path: %i[RdSAP_Report Report_Header] },
          assessment_id: { root: :report_header, path: %i[RRN] },
          assessor_id: { root: :report_header, path: %i[
            Energy_Assessor
            Identification_Number
            Membership_Number
          ]},
          property: {
            path: %i[RdSAP_Report Energy_Assessment Property_Summary]
          },
          energy_use: { path: %i[RdSAP_Report Energy_Assessment Energy_Use] },
          renewable_heat_incentive: {
            path: %i[RdSAP_Report Energy_Assessment Renewable_Heat_Incentive]
          },
          address: { path: %i[RdSAP_Report Report_Header Property Address] },
          inspection_date: { root: :report_header, path: %i[Inspection_Date] },
          registration_date: {
            root: :report_header, path: %i[Registration_Date]
          },
          dwelling_type: { root: :property, path: %i[Dwelling_Type] },
          total_floor_area: { root: :property, path: %i[Total_Floor_Area] },
          current_energy_rating: {
            root: :energy_use, path: %i[Energy_Rating_Current]
          },
          potential_energy_rating: {
            root: :energy_use, path: %i[Energy_Rating_Potential]
          },
          current_carbon_emission: {
            root: :energy_use, path: %i[CO2_Emissions_Current]
          },
          potential_carbon_emission: {
            root: :energy_use, path: %i[CO2_Emissions_Potential]
          },
          space_heating: {
            root: :renewable_heat_incentive,
            path: %i[Space_Heating_Existing_Dwelling]
          },
          water_heating: {
            root: :renewable_heat_incentive, path: %i[Water_Heating]
          },
          impact_of_loft_insulation: {
            root: :renewable_heat_incentive, path: %i[Impact_Of_Loft_Insulation]
          },
          impact_of_cavity_insulation: {
            root: :renewable_heat_incentive,
            path: %i[Impact_Of_Cavity_Insulation]
          },
          impact_of_solid_wall_insulation: {
            root: :renewable_heat_incentive,
            path: %i[Impact_Of_Solid_Wall_Insulation]
          },
          address_line_one: { root: :address, path: %i[Address_Line_1] },
          address_line_two: { root: :address, path: %i[Address_Line_2] },
          address_line_three: { root: :address, path: %i[Address_Line_3] },
          town: { root: :address, path: %i[Post_Town] },
          postcode: { root: :address, path: %i[Postcode] },
          improvements: {
            path: %i[
              RdSAP_Report
              Energy_Assessment
              Suggested_Improvements
              Improvement
            ],
            extract: {
              sequence: {path: [:Sequence]},
              improvement_code: {path: [:Improvement_Details, :Improvement_Number]},
              indicative_cost: {path: [:Indicative_Cost]},
              typical_saving: {path: [:Typical_Saving]},
              improvement_category: {path: [:Improvement_Category]},
              improvement_type: {path: [:Improvement_Type]},
              energy_performance_rating_improvement:
                {path: [:Energy_Performance_Rating]},
              environmental_impact_rating_improvement:
                {path: :Environmental_Impact_Rating},
              green_deal_category_code: {path: [:Green_Deal_Category]}
            }
          }
        }
      },
      'SAP-Schema-17.1': {
        report_type: 'SAP',
        schema_path:
          'api/schemas/xml/SAP-Schema-17.1/SAP/Templates/SAP-Report.xsd',
        data: {
          report_header: { path: %i[SAP_Report Report_Header] },
          assessment_id: { root: :report_header, path: %i[RRN] },
          assessor_id: { root: :report_header, path: %i[
            Home_Inspector
            Identification_Number
            Certificate_Number
          ]},
          renewable_heat_incentive: {
            path: %i[SAP_Report Energy_Assessment Renewable_Heat_Incentive]
          },
          energy_use: { path: %i[SAP_Report Energy_Assessment Energy_Use] },
          address: { path: %i[SAP_Report Report_Header Property Address] },
          property: { path: %i[SAP_Report Energy_Assessment Property_Summary] },
          dwelling_type: { root: :property, path: %i[Dwelling_Type] },
          total_floor_area: { root: :property, path: %i[Total_Floor_Area] },
          address_line_one: { root: :address, path: %i[Address_Line_1] },
          town: { root: :address, path: %i[Post_Town] },
          postcode: { root: :address, path: %i[Postcode] },
          inspection_date: { root: :report_header, path: %i[Inspection_Date] },
          registration_date: {
            root: :report_header, path: %i[Registration_Date]
          },
          new_space_heating: {
            root: :renewable_heat_incentive,
            path: %i[RHI_New_Dwelling Space_Heating]
          },
          space_heating: {
            root: :renewable_heat_incentive,
            path: %i[RHI_Existing_Dwelling Space_Heating_Existing_Dwelling]
          },
          new_water_heating: {
            root: :renewable_heat_incentive,
            path: %i[RHI_New_Dwelling Water_Heating]
          },
          water_heating: {
            root: :renewable_heat_incentive,
            path: %i[RHI_Existing_Dwelling Water_Heating]
          },
          impact_of_loft_insulation: {
            root: :renewable_heat_incentive,
            path: %i[RHI_Existing_Dwelling Impact_Of_Loft_Insulation]
          },
          impact_of_cavity_insulation: {
            root: :renewable_heat_incentive,
            path: %i[RHI_Existing_Dwelling Impact_Of_Cavity_Insulation]
          },
          impact_of_solid_wall_insulation: {
            root: :renewable_heat_incentive,
            path: %i[RHI_Existing_Dwelling Impact_Of_Solid_Wall_Insulation]
          },
          current_energy_rating: {
            root: :energy_use, path: %i[Energy_Rating_Current]
          },
          potential_energy_rating: {
            root: :energy_use, path: %i[Energy_Rating_Potential]
          },
          current_carbon_emission: {
            root: :energy_use, path: %i[CO2_Emissions_Current]
          },
          potential_carbon_emission: {
            root: :energy_use, path: %i[CO2_Emissions_Potential]
          },
          improvements: {
            path: %i[
              SAP_Report
              Energy_Assessment
              Suggested_Improvements
              Improvement
            ],
            extract: {
              sequence: {path: [:Sequence]},
              improvement_code: {path: [:Improvement_Details, :Improvement_Number]},
              indicative_cost: {path: [:Indicative_Cost]},
              typical_saving: {path: [:Typical_Saving]},
              improvement_category: {path: [:Improvement_Category]},
              improvement_type: {path: [:Improvement_Type]},
              energy_performance_rating_improvement:
                {path: [:Energy_Performance_Rating]},
              environmental_impact_rating_improvement:
                {path: [:Environmental_Impact_Rating]},
              green_deal_category_code: {path: [:Green_Deal_Category]}
            }
          }
        }
      }
    }.freeze

    def initialize(data, schema_name)
      @data = data
      @schema_name = schema_name.to_sym
    end

    def schema_exists?
      SCHEMAS.key?(@schema_name)
    end

    def fetch_data
      data = {}

      SCHEMAS[@schema_name][:data].each do |key, settings|
        path =
          if settings.key?(:root)
            SCHEMAS[@schema_name][:data][settings[:root]][:path]
          else
            []
          end
        path += settings[:path]

        data[key] = @data.dig(*path)
      end

      data
    end

    def fetch_raw_data
      @data
    end

    def extract(data, key = :improvements, target_domain = Domain::RecommendedImprovement)
      extracter = data[key]
      if extracter.nil?
        []
      else
        unless extracter.is_a? Array
          extracter = [extracter]
        end

        extracter.map do |i|
          SCHEMAS[@schema_name][:data]
          extractor_inner = {assessment_id: data[:assessment_id]}

          SCHEMAS[@schema_name][:data][key][:extract].each do |key2, value|
            extractor_inner[key2] = i.dig(*value[:path])
          end

          extractor_inner[:sequence] = extractor_inner[:sequence].to_i

          target_domain.new(
            extractor_inner
          )
        end
      end
    end

    def schema_path
      SCHEMAS[@schema_name][:schema_path]
    end

    def type
      SCHEMAS[@schema_name][:report_type]
    end
  end
end
