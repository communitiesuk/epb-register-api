module Controller
  class EpcController < Controller::BaseController
    get '/api/epc/domestic/:certificate_id', jwt_auth: [] do
      not_found_error('Certificate not found')
    end

    put '/api/epc/domestic/:certificate_id', jwt_auth: [] do
    end
  end
end
