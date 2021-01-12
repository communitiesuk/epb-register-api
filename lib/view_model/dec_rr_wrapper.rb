module ViewModel
  class DecRrWrapper
    TYPE_OF_ASSESSMENT = "DEC-RR".freeze

    def initialize(xml, schema_type)
      case schema_type
      when "CEPC-8.0.0"
        @view_model = ViewModel::Cepc800::DecRr.new xml
      when "CEPC-NI-8.0.0"
        @view_model = ViewModel::CepcNi800::DecRr.new xml
      when "CEPC-7.1"
        @view_model = ViewModel::Cepc71::DecRr.new xml
      when "CEPC-7.0"
        @view_model = ViewModel::Cepc70::DecRr.new xml
      when "CEPC-6.0"
        @view_model = ViewModel::Cepc60::DecRr.new xml
      when "CEPC-5.1"
        @view_model = ViewModel::Cepc51::DecRr.new xml
      when "CEPC-5.0"
        @view_model = ViewModel::Cepc50::DecRr.new xml
      when "CEPC-4.0"
        @view_model = ViewModel::Cepc40::DecRr.new xml
      when "CEPC-3.1"
        @view_model = ViewModel::Cepc40::DecRr.new xml
      else
        raise ArgumentError, "Unsupported schema type"
      end
    end

    def type
      :DEC_RR
    end

    def to_hash
      {
        type_of_assessment: TYPE_OF_ASSESSMENT,
        assessment_id: @view_model.assessment_id,
        report_type: @view_model.report_type,
        date_of_assessment: @view_model.date_of_assessment,
        date_of_registration: @view_model.date_of_registration,
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
        short_payback_recommendations:
          @view_model.short_payback_recommendations,
        medium_payback_recommendations:
          @view_model.medium_payback_recommendations,
        long_payback_recommendations: @view_model.long_payback_recommendations,
        other_recommendations: @view_model.other_recommendations,
        technical_information: {
          building_environment: @view_model.building_environment,
          floor_area: @view_model.floor_area,
          occupier: @view_model.occupier,
          property_type: @view_model.property_type,
          renewable_sources: @view_model.renewable_sources,
          discounted_energy: @view_model.discounted_energy,
          date_of_issue: @view_model.date_of_issue,
          calculation_tool: @view_model.calculation_tool,
          inspection_type: @view_model.inspection_type,
        },
        site_service_one: @view_model.site_service_one,
        site_service_two: @view_model.site_service_two,
        site_service_three: @view_model.site_service_three,
        related_rrn: @view_model.related_rrn,
      }
    end

    def get_view_model
      @view_model
    end
  end
end
