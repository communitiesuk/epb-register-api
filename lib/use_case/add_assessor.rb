module UseCase
  class AddAssessor
    class SchemeNotFoundException < Exception; end

    class InvalidAssessorDetailsException < Exception; end

    class AssessorRegisteredOnAnotherScheme < Exception; end

    def initialize(schemes_gateway, assessors_gateway)
      @schemes_gateway = schemes_gateway
      @assessors_gateway = assessors_gateway
    end

    def execute(add_assessor_request)
      scheme =
        @schemes_gateway.all.select do |scheme|
          scheme[:scheme_id].to_s == add_assessor_request.registered_by_id.to_s
        end.first
      raise SchemeNotFoundException unless scheme
      existing_assessor =
        @assessors_gateway.fetch(add_assessor_request.scheme_assessor_id)

      if existing_assessor &&
           existing_assessor.registered_by_id.to_s !=
             add_assessor_request.registered_by_id.to_s
        raise AssessorRegisteredOnAnotherScheme
      end

      assessor =
        Domain::Assessor.new(
          add_assessor_request.scheme_assessor_id,
          add_assessor_request.first_name,
          add_assessor_request.last_name,
          add_assessor_request.middle_names,
          add_assessor_request.date_of_birth,
          add_assessor_request.email,
          add_assessor_request.telephone_number,
          add_assessor_request.registered_by_id,
          scheme[:name],
          add_assessor_request.search_results_comparison_postcode,
          add_assessor_request.domestic_rd_sap_qualification
        )

      @assessors_gateway.update(assessor)

      {
        assessor_was_newly_created: (existing_assessor == nil),
        assessor: assessor
      }
    end
  end
end
