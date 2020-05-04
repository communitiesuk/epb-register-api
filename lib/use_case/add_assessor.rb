module UseCase
  class AddAssessor
    class SchemeNotFoundException < StandardError; end

    class InvalidAssessorDetailsException < StandardError; end

    class AssessorRegisteredOnAnotherScheme < StandardError; end

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
          scheme_assessor_id: add_assessor_request.scheme_assessor_id,
          first_name: add_assessor_request.first_name,
          last_name: add_assessor_request.last_name,
          middle_names: add_assessor_request.middle_names,
          date_of_birth: add_assessor_request.date_of_birth,
          email: add_assessor_request.email,
          telephone_number: add_assessor_request.telephone_number,
          registered_by_id: add_assessor_request.registered_by_id,
          registered_by_name: scheme[:name],
          search_results_comparison_postcode:
            add_assessor_request.search_results_comparison_postcode,
          domestic_sap_qualification:
            add_assessor_request.domestic_sap_qualification,
          domestic_rd_sap_qualification:
            add_assessor_request.domestic_rd_sap_qualification,
          non_domestic_sp3_qualification:
            add_assessor_request.non_domestic_sp3_qualification,
          non_domestic_cc4_qualification:
            add_assessor_request.non_domestic_cc4_qualification,
          non_domestic_dec_qualification:
            add_assessor_request.non_domestic_dec_qualification,
          non_domestic_nos3_qualification:
            add_assessor_request.non_domestic_nos3_qualification,
          non_domestic_nos4_qualification:
            add_assessor_request.non_domestic_nos4_qualification,
          non_domestic_nos5_qualification:
            add_assessor_request.non_domestic_nos5_qualification,
        )

      @assessors_gateway.update(assessor)

      { assessor_was_newly_created: existing_assessor.nil?, assessor: assessor }
    end
  end
end
