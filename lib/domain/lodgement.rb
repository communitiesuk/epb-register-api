# frozen_string_literal: true

module Domain
  class Lodgement
    SCHEMAS = {
      'RdSAP-Schema-19.0': {
        schema_path:
          'api/schemas/xml/RdSAP-Schema-19.0/RdSAP/Templates/RdSAP-Report.xsd',
        scheme_assessor_id_location: %i[
          RdSAP_Report
          Report_Header
          Energy_Assessor
          Identification_Number
          Membership_Number
        ],
        data: {
          report_header: { path: %i[RdSAP_Report Report_Header] },
          assessment_id: { path: %i[RdSAP_Report Report_Header RRN] },
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
          improvement: {
            path: %i[
              RdSAP_Report
              Energy_Assessment
              Suggested_Improvements
              Improvement
            ]
          }
        }
      },
      'SAP-Schema-17.1': {
        schema_path:
          'api/schemas/xml/SAP-Schema-17.1/SAP/Templates/SAP-Report.xsd',
        scheme_assessor_id_location: %i[
          SAP_Report
          Report_Header
          Home_Inspector
          Identification_Number
          Certificate_Number
        ],
        data: {
          report_header: { path: %i[SAP_Report Report_Header] },
          assessment_id: { path: %i[SAP_Report Report_Header RRN] },
          renewable_heat_incentive: {
            path: %i[SAP_Report Energy_Assessment Renewable_Heat_Incentive]
          },
          property: {
            path: %i[SAP_Report Energy_Assessment Property],
          },
          address_line_one: { root: :property, path: %i[Address_Line_1] },
          town: { root: :property, path: %i[Post_Town] },
          postcode: { root: :property, path: %i[Postcode] },
          inspection_date: { root: :report_header, path: %i[Inspection_Date] },
          registration_date: { root: :report_header, path: %i[Registration_Date] },
          space_heating: {
            root: :renewable_heat_incentive,
            path: %i[RHI-New-Dwelling Space_Heating]
          },
          water_heating: {
            root: :renewable_heat_incentive,
            path: %i[RHI-New-Dwelling Water_Heating]
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

    def suggested_improvements
      suggested_improvements =
        @data.dig(*SCHEMAS[@schema_name][:data][:improvement][:path])

      if suggested_improvements.nil?
        []
      else
        unless suggested_improvements.is_a? Array
          suggested_improvements = [suggested_improvements]
        end

        suggested_improvements.map do |i|
          Domain::RecommendedImprovement.new(
            assessment_id,
            i[:Sequence].to_i,
            i[:Improvement_Details][:Improvement_Number],
            i[:Indicative_Cost],
            i[:Typical_Saving],
            i[:Improvement_Category],
            i[:Improvement_Type],
            i[:Energy_Performance_Rating],
            i[:Environmental_Impact_Rating],
            i[:Green_Deal_Category]
          )
        end
      end
    end

    def schema_path
      SCHEMAS[@schema_name][:schema_path]
    end

    def scheme_assessor_id
      @data.dig(*SCHEMAS[@schema_name][:scheme_assessor_id_location])
    end

    def assessment_id
      @data.dig(*SCHEMAS[@schema_name][:data][:assessment_id][:path])
    end
  end
end
