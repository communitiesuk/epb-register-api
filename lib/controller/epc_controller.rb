module Controller
  class EpcController < Controller::BaseController
    PUT_SCHEMA = {
      type: 'object',
      required: %w[
        addressSummary
        dateOfAssessment
        dateOfCertificate
        totalFloorArea
        dwellingType
        typeOfAssessment
      ],
      properties: {
        addressSummary: { type: 'string' },
        dateOfAssessment: { type: 'string', format: 'iso-date' },
        dateOfCertificate: { type: 'string', format: 'iso-date' },
        totalFloorArea: { type: 'integer' },
        dwellingType: { type: 'string' },
        typeOfAssessment: { type: 'string', enum: %w[SAP RdSAP] }
      }
    }

    get '/api/certificates/epc/domestic/:certificate_id', jwt_auth: [] do
      certificate_id = params[:certificate_id]
      result =
        @container.get_object(:fetch_domestic_epcs_use_case).execute(
          certificate_id
        )
      json_response(200, result)
    rescue Exception => e
      case e
      when UseCase::FetchDomesticEpc::NotFoundException
        not_found_error('Certificate not found')
      else
        server_error(e)
      end
    end

    put '/api/certificates/epc/domestic/:certificate_id', jwt_auth: [] do
      certificate_id = params[:certificate_id]
      migrate_epc = @container.get_object(:migrate_domestic_epc_use_case)
      epc_body = request_body(PUT_SCHEMA)
      result = migrate_epc.execute(certificate_id, epc_body)

      json_response(200, result)
    rescue Exception => e
      case e
      when JSON::Schema::ValidationError
        error_response(422, 'INVALID_REQUEST', e.message)
      end
    end
  end
end
