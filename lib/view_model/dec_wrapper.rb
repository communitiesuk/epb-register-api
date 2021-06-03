module ViewModel
  class DecWrapper
    TYPE_OF_ASSESSMENT = "DEC".freeze
    attr_accessor :schema_type

    def initialize(xml, schema_type)
      @schema_type = schema_type
      case @schema_type
      when "CEPC-8.0.0"
        @view_model = ViewModel::Cepc800::Dec.new xml
      when "CEPC-NI-8.0.0"
        @view_model = ViewModel::CepcNi800::Dec.new xml
      when "CEPC-7.1"
        @view_model = ViewModel::Cepc71::Dec.new xml
      when "CEPC-7.0"
        @view_model = ViewModel::Cepc70::Dec.new xml
      when "CEPC-6.0"
        @view_model = ViewModel::Cepc60::Dec.new xml
      when "CEPC-5.1"
        @view_model = ViewModel::Cepc51::Dec.new xml
      when "CEPC-5.0"
        @view_model = ViewModel::Cepc50::Dec.new xml
      when "CEPC-4.0"
        @view_model = ViewModel::Cepc40::Dec.new xml
      when "CEPC-3.1"
        @view_model = ViewModel::Cepc40::Dec.new xml
      else
        raise ArgumentError, "Unsupported schema type"
      end
    end

    def type
      :DEC
    end

    def to_hash
      {
        assessment_id: @view_model.assessment_id,
        date_of_assessment: @view_model.date_of_assessment,
        date_of_expiry: @view_model.date_of_expiry,
        date_of_registration: @view_model.date_of_registration,
        address: {
          address_id: @view_model.address_id,
          address_line1: @view_model.address_line1,
          address_line2: @view_model.address_line2,
          address_line3: @view_model.address_line3,
          address_line4: @view_model.address_line4,
          town: @view_model.town,
          postcode: @view_model.postcode,
        },
        type_of_assessment: "DEC",
        schema_version: @schema_type.gsub(/[a-zA-Z-]/, "").to_f,
        report_type: @view_model.report_type,
        current_assessment: {
          date: @view_model.current_assessment_date,
          energy_efficiency_rating: @view_model.energy_efficiency_rating,
          energy_efficiency_band:
            Helper::EnergyBandCalculator.commercial(
              @view_model.energy_efficiency_rating.to_i,
            ),
          heating_co2: @view_model.current_heating_co2,
          electricity_co2: @view_model.current_electricity_co2,
          renewables_co2: @view_model.current_renewables_co2,
        },
        year1_assessment: {
          date: @view_model.year1_assessment_date,
          energy_efficiency_rating: @view_model.year1_energy_efficiency_rating,
          energy_efficiency_band:
            Helper::EnergyBandCalculator.commercial(
              @view_model.year1_energy_efficiency_rating.to_i,
            ),
          heating_co2: @view_model.year1_heating_co2,
          electricity_co2: @view_model.year1_electricity_co2,
          renewables_co2: @view_model.year1_renewables_co2,
        },
        year2_assessment: {
          date: @view_model.year2_assessment_date,
          energy_efficiency_rating: @view_model.year2_energy_efficiency_rating,
          energy_efficiency_band:
            Helper::EnergyBandCalculator.commercial(
              @view_model.year2_energy_efficiency_rating.to_i,
            ),
          heating_co2: @view_model.year2_heating_co2,
          electricity_co2: @view_model.year2_electricity_co2,
          renewables_co2: @view_model.year2_renewables_co2,
        },
        technical_information: {
          main_heating_fuel: @view_model.main_heating_fuel,
          building_environment: @view_model.building_environment,
          floor_area: @view_model.floor_area,
          occupier: @view_model.occupier,
          asset_rating: @view_model.asset_rating,
          annual_energy_use_fuel_thermal:
            @view_model.annual_energy_use_fuel_thermal,
          annual_energy_use_electrical:
            @view_model.annual_energy_use_electrical,
          typical_thermal_use: @view_model.typical_thermal_use,
          typical_electrical_use: @view_model.typical_electrical_use,
          renewables_fuel_thermal: @view_model.renewables_fuel_thermal,
          renewables_electrical: @view_model.renewables_electrical,
        },
        assessor: {
          scheme_assessor_id: @view_model.scheme_assessor_id,
          name: @view_model.assessor_name,
          company_details: {
            name: @view_model.company_name,
            address: @view_model.company_address,
          },
          contact_details: {
            email: @view_model.assessor_email,
            telephone: @view_model.assessor_telephone,
          },
        },
        administrative_information: {
          issue_date: @view_model.date_of_issue,
          calculation_tool: @view_model.calculation_tool,
          related_party_disclosure: @view_model.dec_related_party_disclosure,
          related_rrn: @view_model.related_rrn,
        },
      }
    end

    # create hash for data requested by Open Data Communities
    # hash keys will be turned into columns for expected csv
    def to_report
      {
        assessment_id: @view_model.assessment_id,
        building_reference_number: @view_model.building_reference_number,
        address1: @view_model.address_line1,
        address2: @view_model.address_line2,
        address3: @view_model.address_line3,
        posttown: @view_model.town,
        postcode: @view_model.postcode,
        current_operational_rating: @view_model.energy_efficiency_rating,
        yr1_operational_rating: @view_model.year1_energy_efficiency_rating,
        yr2_operational_rating: @view_model.year2_energy_efficiency_rating,
        operational_rating_band:
          Helper::EnergyBandCalculator.commercial(
            @view_model.energy_efficiency_rating.to_i,
          ).upcase,
        electric_co2: @view_model.current_electricity_co2,
        heating_co2: @view_model.current_heating_co2,
        renewables_co2: @view_model.current_renewables_co2,
        property_type: @view_model.property_type,
        inspection_date: @view_model.date_of_assessment,
        nominated_date: @view_model.current_assessment_date,
        or_assessment_end_date: @view_model.or_assessment_end_date,
        lodgement_date: @view_model.date_of_registration,
        lodgement_datetime: "",
        main_benchmark: @view_model.main_benchmark,
        main_heating_fuel: @view_model.main_heating_fuel,
        special_energy_uses: @view_model.special_energy_uses,
        renewable_sources: @view_model.renewables_fuel_thermal,
        total_floor_area: @view_model.floor_area,
        occupancy_level: @view_model.occupancy_level,
        annual_thermal_fuel_usage: @view_model.annual_energy_use_fuel_thermal,
        typical_thermal_fuel_usage: @view_model.typical_thermal_use,
        annual_electrical_fuel_usage: @view_model.annual_energy_use_electrical,
        typical_electrical_fuel_usage: @view_model.typical_electrical_use,
        renewables_fuel_thermal: @view_model.renewables_fuel_thermal,
        renewables_electrical: @view_model.renewables_electrical,
        yr1_electricity_co2: @view_model.year1_electricity_co2,
        yr2_electricity_co2: @view_model.year2_electricity_co2,
        yr1_heating_co2: @view_model.year1_heating_co2,
        yr2_heating_co2: @view_model.year2_heating_co2,
        yr1_renewables_co2: @view_model.year1_renewables_co2,
        yr2_renewables_co2: @view_model.year2_renewables_co2,
        # open data request for return value to be Y OR N
        aircon_present:
          if !@view_model.ac_present.nil? &&
              @view_model.ac_present.upcase == "YES"
            "Y"
          else
            "N"
          end,
        aircon_kw_rating: @view_model.ac_kw_rating,
        estimated_aircon_kw_rating: @view_model.estimated_ac_kw_rating,
        ac_inspection_commissioned: @view_model.ac_inspection_commissioned,
        building_environment: @view_model.building_environment,
        building_category: @view_model.building_category,
        report_type: @view_model.report_type,
        other_fuel: @view_model.other_fuel,
      }
    end

    def get_view_model
      @view_model
    end
  end
end
