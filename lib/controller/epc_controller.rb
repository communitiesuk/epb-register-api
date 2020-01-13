module Controller
  class EpcController < Controller::BaseController
    get '/api/epc/domestic/:certificate_id', jwt_auth: [] do
      not_found_error('Certificate not found')
    end

    put '/api/epc/domestic/:certificate_id', jwt_auth: [] do
      certificate_id = params[:certificate_id]
      migrate_epc = @container.get_object(:migrate_domestic_epc_use_case)
      epc_body = request_body

      json_response(200, migrate_epc.execute(certificate_id, epc_body))
    end
  end
end
