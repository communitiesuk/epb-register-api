module Controller
  class AssessorController < Controller::BaseController
    PUT_SCHEMA = {
      type: "object",
      required: %w[firstName lastName dateOfBirth],
      properties: {
        firstName: { type: "string" },
        lastName: { type: "string" },
        middleNames: { type: "string" },
        dateOfBirth: { type: "string", format: "iso-date" },
        searchResultsComparisonPostcode: { type: "string" },
        alsoKnownAs: { type: %w[string null] },
        address: {
          type: "object",
          properties: {
            addressLine1: { type: %w[string null] },
            addressLine2: { type: %w[string null] },
            addressLine3: { type: %w[string null] },
            town: { type: %w[string null] },
            postcode: { type: %w[string null] },
          },
        },
        companyDetails: {
          type: "object",
          properties: {
            companyRegNo: { type: %w[string null] },
            companyAddressLine1: { type: %w[string null] },
            companyAddressLine2: { type: %w[string null] },
            companyAddressLine3: { type: %w[string null] },
            companyTown: { type: %w[string null] },
            companyPostcode: { type: %w[string null] },
            companyWebsite: { type: %w[string null] },
            companyTelephoneNumber: { type: %w[string null] },
            companyEmail: { type: %w[string null] },
            companyName: { type: %w[string null] },
          },
        },
        contactDetails: {
          type: "object",
          properties: {
            telephoneNumber: { type: "string", format: "telephone" },
            email: { type: "string", format: "email" },
          },
        },
        qualifications: {
          type: "object",
          properties: {
            domesticSap: {
              type: "string", enum: %w[ACTIVE INACTIVE STRUCKOFF SUSPENDED]
            },
            domesticRdSap: {
              type: "string", enum: %w[ACTIVE INACTIVE STRUCKOFF SUSPENDED]
            },
            nonDomesticSp3: {
              type: "string", enum: %w[ACTIVE INACTIVE STRUCKOFF SUSPENDED]
            },
            nonDomesticCc4: {
              type: "string", enum: %w[ACTIVE INACTIVE STRUCKOFF SUSPENDED]
            },
            nonDomesticDec: {
              type: "string", enum: %w[ACTIVE INACTIVE STRUCKOFF SUSPENDED]
            },
            nonDomesticNos3: {
              type: "string", enum: %w[ACTIVE INACTIVE STRUCKOFF SUSPENDED]
            },
            nonDomesticNos4: {
              type: "string", enum: %w[ACTIVE INACTIVE STRUCKOFF SUSPENDED]
            },
            nonDomesticNos5: {
              type: "string", enum: %w[ACTIVE INACTIVE STRUCKOFF SUSPENDED]
            },
            gda: {
              type: "string", enum: %w[ACTIVE INACTIVE STRUCKOFF SUSPENDED]
            },
          },
        },
      },
    }.freeze

    def search_by_name(name)
      result = UseCase::FindAssessorsByName.new.execute(name)

      result[:data] = assessor_list_results_filter(result)
      json_api_response(code: 200, data: result, burrow_key: :assessors)
    end

    def search_by_postcode(postcode, qualifications)
      postcode = postcode.upcase
      postcode = postcode.insert(-4, " ") if postcode[-4] != " "

      result =
        UseCase::FindAssessorsByPostcode.new.execute(
          postcode,
          qualifications.split(","),
        )

      result[:data] = assessor_list_results_filter(result)

      json_api_response(code: 200, data: result, burrow_key: :assessors)
    end

    def assessor_list_results_filter(unfiltered_results)
      if unfiltered_results[:data]
        unfiltered_results[:data].map do |r|
          r.slice(
            :registered_by,
            :scheme_assessor_id,
            :first_name,
            :last_name,
            :middle_names,
            :date_of_birth,
            :email,
            :telephone_number,
            :search_results_comparison_postcode,
            :contact_details,
            :qualifications,
            :distance_from_postcode_in_miles,
          )
        end
      end
    end

    get "/api/schemes/:scheme_id/assessors",
        jwt_auth: %w[scheme:assessor:list] do
      scheme_id = params[:scheme_id]
      sup = env[:jwt_auth].supplemental("scheme_ids")

      unless sup.include? scheme_id.to_i
        forbidden(
          "UNAUTHORISED",
          "You are not authorised to perform this request",
        )
      end

      result = UseCase::FetchAssessorList.new.execute(scheme_id)

      json_api_response(code: 200, data: { assessors: result.map(&:to_hash) })
    rescue UseCase::FetchAssessorList::SchemeNotFoundException
      not_found_error("The requested scheme was not found")
    end

    get "/api/assessors", jwt_auth: %w[assessor:search] do
      if params.key?(:name)
        search_by_name(params[:name])
      elsif params.key?(:postcode) && params.key?(:qualification)
        search_by_postcode(params[:postcode], params[:qualification])
      else
        error_response(
          400,
          "INVALID_QUERY",
          "Must specify either name or postcode & qualification when searching",
        )
      end
    rescue StandardError => e
      case e
      when UseCase::FindAssessorsByPostcode::PostcodeNotRegistered
        not_found_error("The requested postcode is not registered")
      when UseCase::FindAssessorsByPostcode::PostcodeNotValid
        error_response(
          400,
          "INVALID_REQUEST",
          "The requested postcode is not valid",
        )
      when ArgumentError
        error_response(400, "INVALID_QUERY", e.message)
      else
        server_error(e.message)
      end
    end

    get "/api/schemes/:scheme_id/assessors/:scheme_assessor_id",
        jwt_auth: %w[scheme:assessor:fetch] do
      scheme_id = params[:scheme_id]
      scheme_assessor_id = params[:scheme_assessor_id]
      sup = env[:jwt_auth].supplemental("scheme_ids")

      unless sup.include? scheme_id.to_i
        forbidden(
          "UNAUTHORISED",
          "You are not authorised to perform this request",
        )
      end

      result = UseCase::FetchAssessor.new.execute(scheme_id, scheme_assessor_id)
      json_api_response(code: 200, data: result.to_hash)
    rescue StandardError => e
      case e
      when UseCase::FetchAssessor::SchemeNotFoundException
        not_found_error("The requested scheme was not found")
      when UseCase::FetchAssessor::AssessorNotFoundException
        not_found_error("The requested assessor was not found")
      else
        server_error(e.message)
      end
    end

    put "/api/schemes/:scheme_id/assessors/:scheme_assessor_id",
        jwt_auth: %w[scheme:assessor:update] do
      scheme_id = params["scheme_id"]
      scheme_assessor_id = params["scheme_assessor_id"]
      sup = env[:jwt_auth].supplemental("scheme_ids")
      unless sup.include? scheme_id.to_i
        forbidden(
          "UNAUTHORISED",
          "You are not authorised to perform this request",
        )
      end

      assessor_details = request_body(PUT_SCHEMA)

      create_assessor_response =
        UseCase::AddAssessor.new.execute(
          Boundary::AssessorRequest.new(
            body: assessor_details,
            scheme_assessor_id: scheme_assessor_id,
            registered_by_id: scheme_id,
          ),
        )
      assessor_record = create_assessor_response[:assessor]

      if create_assessor_response[:assessor_was_newly_created]
        @events.event(:new_assessor_registered, scheme_assessor_id)
        json_api_response(code: 201, data: create_assessor_response[:assessor])
      else
        @events.event(:assessor_updated, scheme_assessor_id)
        json_api_response(code: 200, data: assessor_record.to_hash)
      end
    rescue StandardError => e
      case e
      when UseCase::AddAssessor::SchemeNotFoundException
        not_found_error("The requested scheme was not found")
      when UseCase::AddAssessor::AssessorRegisteredOnAnotherScheme
        error_response(
          409,
          "ASSESSOR_ID_ON_ANOTHER_SCHEME",
          "The assessor ID you are trying to update is registered by a different scheme",
        )
      when JSON::ParserError
        error_response(400, "INVALID_REQUEST", e.message)
      when JSON::Schema::ValidationError
        error_response(422, "INVALID_REQUEST", e.message)
      else
        server_error(e.message)
      end
    end
  end
end
