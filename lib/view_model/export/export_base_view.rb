module ViewModel::Export
  class ExportBaseView
    REDACTED = "REDACTED".freeze
    private_constant :REDACTED

    attr_accessor :type_of_assessment

    def initialize(certificate_wrapper)
      @view_model = certificate_wrapper.get_view_model
      @type_of_assessment = certificate_wrapper.type.to_s
    end


    def address
      {
        address_id: @view_model.address_id,
        address_line1: @view_model.address_line1,
        address_line2: @view_model.address_line2,
        address_line3: @view_model.address_line3,
        address_line4:
          if @view_model.respond_to?(:address_line4)
            @view_model.address_line4
          end,
        postcode: @view_model.postcode,
        town: @view_model.town,
      }
    end

    def assessor
      {
        "scheme_assessor_id": REDACTED, # @view_model.scheme_assessor_id,
        "name": REDACTED, # @view_model.assessor_name,
        "email": REDACTED, # @view_model.assessor_email,
        "telephone": REDACTED, # @view_model.assessor_telephone,
      }
    end

    def heat_demand
      {
        current_space_heating_demand:
          @view_model.current_space_heating_demand&.to_i,
        current_water_heating_demand:
          @view_model.current_water_heating_demand&.to_i,
        impact_of_cavity_insulation: @view_model.impact_of_cavity_insulation,
        impact_of_loft_insulation: @view_model.impact_of_loft_insulation,
        impact_of_solid_wall_insulation:
          @view_model.impact_of_solid_wall_insulation,
      }
    end

    def assessor
      {
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
      }
    end


  end
end
