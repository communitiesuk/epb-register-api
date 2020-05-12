module Controller
  class AddressController < Controller::BaseController
    get "/api/address/search",
        jwt_auth: %w[address:search] do
    end
  end
end
