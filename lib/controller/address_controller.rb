module Controller
  class AddressController < Controller::BaseController
    get "/api/address/search", jwt_auth: %w[address:search] do
      error_response(
        422,
        "INVALID_QUERY",
        "Must specify either postcode or street and town or buildingReferenceNumber",
      )
    end
  end
end
