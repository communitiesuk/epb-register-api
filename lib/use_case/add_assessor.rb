module UseCase
  class AddAssessor
    ASSESSOR_ID_REGEX = /[A-Z\/_]{4}[0-9]{6}/.freeze

    class SchemeNotFoundException < StandardError
    end

    class InvalidAssessorIdException < StandardError
    end

    class InvalidAssessorDetailsException < StandardError
    end

    class AssessorRegisteredOnAnotherScheme < StandardError
    end

    def initialize
      @schemes_gateway = Gateway::SchemesGateway.new
      @assessors_gateway = Gateway::AssessorsGateway.new
      @assessors_status_events_gateway =
        Gateway::AssessorsStatusEventsGateway.new
    end

    def execute(add_assessor_request, auth_client_id)
      unless ASSESSOR_ID_REGEX.match?(add_assessor_request.scheme_assessor_id)
        raise InvalidAssessorIdException,
              "The ID provided for the assessor is not in the expected format: \"%s\"" %
          add_assessor_request.scheme_assessor_id
      end

      scheme =
        @schemes_gateway.all.find do |scheme|
          scheme[:scheme_id].to_s == add_assessor_request.registered_by_id.to_s
        end

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
          also_known_as: add_assessor_request.also_known_as,
          address_line1: add_assessor_request.address_line1,
          address_line2: add_assessor_request.address_line2,
          address_line3: add_assessor_request.address_line3,
          town: add_assessor_request.town,
          postcode: add_assessor_request.postcode,
          company_reg_no: add_assessor_request.company_reg_no,
          company_address_line1: add_assessor_request.company_address_line1,
          company_address_line2: add_assessor_request.company_address_line2,
          company_address_line3: add_assessor_request.company_address_line3,
          company_town: add_assessor_request.company_town,
          company_postcode: add_assessor_request.company_postcode,
          company_website: add_assessor_request.company_website,
          company_telephone_number:
            add_assessor_request.company_telephone_number,
          company_email: add_assessor_request.company_email,
          company_name: add_assessor_request.company_name,
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
          gda_qualification: add_assessor_request.gda_qualification,
        )

      @assessors_gateway.update(assessor)

      if existing_assessor
        previous_qualifications = existing_assessor.to_hash[:qualifications]
        new_qualifications = assessor.to_hash[:qualifications]

        previous_qualifications.each do |qualification, status|
          next unless status != new_qualifications[qualification]

          @assessors_status_events_gateway.add(
            Domain::AssessorsStatusEvent.new(
              assessor: assessor.to_hash,
              scheme_assessor_id: assessor.scheme_assessor_id,
              qualification_type: qualification,
              previous_status: status,
              new_status: new_qualifications[qualification],
              auth_client_id: auth_client_id,
            ),
          )
        end
      end

      { assessor_was_newly_created: existing_assessor.nil?, assessor: assessor }
    end
  end
end
