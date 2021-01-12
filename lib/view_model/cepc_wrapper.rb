module ViewModel
  class CepcWrapper
    TYPE_OF_ASSESSMENT = "CEPC".freeze
    def initialize(xml, schema_type)
      case schema_type
      when "CEPC-8.0.0"
        @view_model = ViewModel::Cepc800::Cepc.new xml
      when "CEPC-NI-8.0.0"
        @view_model = ViewModel::CepcNi800::Cepc.new xml
      when "CEPC-7.1"
        @view_model = ViewModel::Cepc71::Cepc.new xml
      when "CEPC-7.0"
        @view_model = ViewModel::Cepc70::Cepc.new xml
      when "CEPC-6.0"
        @view_model = ViewModel::Cepc60::Cepc.new xml
      when "CEPC-5.1"
        @view_model = ViewModel::Cepc51::Cepc.new xml
      when "CEPC-5.0"
        @view_model = ViewModel::Cepc50::Cepc.new xml
      when "CEPC-4.0"
        @view_model = ViewModel::Cepc40::Cepc.new xml
      when "CEPC-3.1"
        @view_model = ViewModel::Cepc40::Cepc.new xml
      else
        raise ArgumentError, "Unsupported schema type"
      end
    end

    def get_energy_rating_band(number)
      case number
      when -Float::INFINITY...0
        "a+"
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

    def type
      :CEPC
    end

    def to_hash
      {
        type_of_assessment: TYPE_OF_ASSESSMENT,
        assessment_id: @view_model.assessment_id,
        date_of_expiry: @view_model.date_of_expiry,
        report_type: @view_model.report_type,
        date_of_assessment: @view_model.date_of_assessment,
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
        technical_information: {
          main_heating_fuel: @view_model.main_heating_fuel,
          building_environment: @view_model.building_environment,
          floor_area: @view_model.floor_area,
          building_level: @view_model.building_level,
          # other_fuel_description: @view_model.other_fuel_description,
        },
        building_emission_rate: @view_model.building_emission_rate,
        primary_energy_use: @view_model.primary_energy_use,
        related_rrn: @view_model.related_rrn,
        new_build_rating: @view_model.new_build_rating,
        new_build_band:
          get_energy_rating_band(@view_model.new_build_rating.to_i),
        existing_build_rating: @view_model.existing_build_rating,
        existing_build_band:
          get_energy_rating_band(@view_model.existing_build_rating.to_i),
        current_energy_efficiency_rating: @view_model.energy_efficiency_rating,
        energy_efficiency_rating: @view_model.energy_efficiency_rating,
        assessor: {
          scheme_assessor_id: @view_model.scheme_assessor_id,
          name: @view_model.assessor_name,
          contact_details: {
            email: @view_model.assessor_email,
            telephone: @view_model.assessor_telephone,
          },
          company_details: {
            name: @view_model.company_name,
            address: @view_model.company_address,
          },
        },
        related_party_disclosure: @view_model.epc_related_party_disclosure,
        current_energy_efficiency_band:
          get_energy_rating_band(@view_model.energy_efficiency_rating.to_i),
        property_type: @view_model.property_type,
        building_complexity: @view_model.building_level,
      }
    end

    # create hash for data requested by Open Data Communities
    # hash keys will be turned into columns for expected csv
    def to_report
      {
        type_of_assessment: TYPE_OF_ASSESSMENT,
        rrn: @view_model.assessment_id,
        report_type: @view_model.report_type,
        inspection_date: @view_model.date_of_assessment,
        lodgement_date: @view_model.date_of_registration,
        building_reference_number: @view_model.address_id,
        address1: @view_model.address_line1,
        address2: @view_model.address_line2,
        address3: @view_model.address_line3,
        address4: @view_model.address_line4,
        posttown: @view_model.town,
        postcode: @view_model.postcode,
        asset_rating: @view_model.energy_efficiency_rating,
        asset_rating_band:
          get_energy_rating_band(@view_model.energy_efficiency_rating.to_i),
        property_type: @view_model.property_type,
        transaction_type: @view_model.transaction_type,
        new_build_benchmark: @view_model.new_build_rating,
        existing_stock_benchmark: @view_model.existing_build_rating,
        building_level: @view_model.building_level,
        main_heating_fuel: @view_model.main_heating_fuel,
        other_fuel_description: @view_model.other_fuel_description,
        special_energy_uses: @view_model.special_energy_uses,
        floor_area: @view_model.floor_area,
        standard_emissions: @view_model.standard_emissions,
        target_emissions: @view_model.target_emissions,
        typical_emissions: @view_model.typical_emissions,
        building_emissions: @view_model.building_emission_rate,
        building_environment: @view_model.building_environment,
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
        ac_inpsection_commissioned: @view_model.ac_inpsection_commissioned,
        primary_energy: @view_model.primary_energy_use,
        other_fuel_desc: @view_model.other_fuel_description,
      }
    end

    def get_view_model
      @view_model
    end
  end
end
