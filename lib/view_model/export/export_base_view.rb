module ViewModel::Export
  class ExportBaseView
    REDACTED = "REDACTED".freeze
    private_constant :REDACTED

    attr_accessor :type_of_assessment

    def initialize(certificate_wrapper, assessment_search)
      @wrapper = certificate_wrapper
      @view_model = certificate_wrapper.get_view_model
      @assessment_search_gateway = assessment_search
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

    def enum_value(method, *value)
      {
        description: Helper::XmlEnumsToOutput.send(method, *value),
        value: value[0],
      }
    end

    def metadata
      result = @assessment_search_gateway.search_by_assessment_id(@view_model.assessment_id).first
      metadata = {}

      metadata[:address_id] = result.get(:address_id)
      metadata[:created_at] = if result.get(:created_at).nil?
                                    DateTime.new(2020,9,27,8,30).to_formatted_s(:iso8601)
                                  else
                                    DateTime.parse(result.get(:created_at).to_s).to_formatted_s(:iso8601)
                                      end
      metadata[:opt_out] = result.get(:opt_out)
      metadata[:cancelled_at] = result.get(:cancelled_at)
      metadata[:not_for_issue_at] = result.get(:not_for_issue_at)
      metadata[:related_rrn] = result.get(:related_rrn)

      metadata
    end
  end
end
