module Controller
  class EpcController < Controller::BaseController
    get '/api/epc/domestic/:certificate_id', jwt_auth: [] do
      not_found_error('Certificate not found')
    end

    put '/api/epc/domestic/:certificate_id', jwt_auth: [] do
      certificate_id = params[:certificate_id]
      json_response(200, {certificate_id: certificate_id})
    end
  end
end
