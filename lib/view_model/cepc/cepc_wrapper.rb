module ViewModel
  module Cepc
    class CepcWrapper
      def initialize(xml, schema_type)
        case schema_type
        when "CEPC-8.0.0"
          @view_model = ViewModel::Cepc::Cepc800.new(xml)
        else
          raise ArgumentError, "Unsupported assessment type"
        end
      end

      def to_hash
        {
          assessment_id: @view_model.assessment_id,
          date_of_expiry: @view_model.date_of_expiry,
          address: {
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
            building_emission_rate: @view_model.building_emission_rate,
          },
        }
      end
    end
  end
end
