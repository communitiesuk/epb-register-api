module ViewModel
  class DecWrapper
    TYPE_OF_ASSESSMENT = "DEC".freeze

    def initialize(xml, schema_type)
      case schema_type
      when "CEPC-8.0.0"
        @view_model = ViewModel::Cepc800::Dec.new xml
      when "CEPC-NI-8.0.0"
        @view_model = ViewModel::CepcNi800::Dec.new xml
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
        date_of_expiry: @view_model.date_of_expiry,
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
        report_type: @view_model.report_type,
        current_assessment: {
          date: @view_model.current_assessment_date,
          energy_efficiency_rating: @view_model.energy_efficiency_rating,
          energy_efficiency_band:
            get_energy_rating_band(@view_model.energy_efficiency_rating.to_i),
          heating_co2: @view_model.current_heating_co2,
          electricity_co2: @view_model.current_electricity_co2,
          renewables_co2: @view_model.current_renewables_co2,
        },
        year1_assessment: {
          date: @view_model.year1_assessment_date,
          energy_efficiency_rating: @view_model.year1_energy_efficiency_rating,
          energy_efficiency_band:
            get_energy_rating_band(
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
            get_energy_rating_band(
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
      }
    end

    def get_energy_rating_band(number)
      case number
      when 0..25
        "a"
      when 26..50
        "b"
      when 51..75
        "c"
      when 76..100
        "d"
      when 101..125
        "e"
      when 126..150
        "f"
      else
        "g"
      end
    end

    def get_view_model
      @view_model
    end
  end
end
