module Controller
  class AddressSearchController < Controller::BaseController
    SEARCH_SCHEMA = {
      oneOf: [
        {
          type: "object",
          required: %w[addressId],
          properties: {
            addressId: {
              type: "string",
              pattern: Helper::RegexHelper::ADDRESS_ID,
            },
          },
        },
        {
          type: "object",
          required: %w[postcode],
          properties: {
            postcode: {
              type: "string",
              pattern: Helper::RegexHelper::POSTCODE,
            },
            buildingNameNumber: { type: "string" },
            addressType: { type: "string", enum: %w[DOMESTIC COMMERCIAL] },
          },
        },
        {
          type: "object",
          required: %w[street town],
          properties: {
            street: { type: "string" },
            town: { type: "string" },
            addressType: { type: "string", enum: %w[DOMESTIC COMMERCIAL] },
          },
        },
      ],
    }.freeze

    get "/api/search/addresses", jwt_auth: %w[address:search] do
      filters = params_body SEARCH_SCHEMA

      use_case =
        if filters.key? :address_id
          UseCase::SearchAddressesByAddressId.new
        elsif filters.key? :postcode
          UseCase::SearchAddressesByPostcode.new
        elsif filters.key? :street
          UseCase::SearchAddressesByStreetAndTown.new
        end

      needed_args = use_case.method(:execute).parameters.map(&:second)

      filters.each_key do |key|
        next if needed_args.include? key

        forbidden "INVALID_REQUEST", "#{key} is not valid in this context.", 422
      end

      results = use_case.execute filters

      json_api_response code: 200,
                        data: { addresses: results.map(&:to_hash) },
                        meta: { filters: filters }
    rescue StandardError => e
      case e
      when JSON::Schema::ValidationError
        error_response 422, "INVALID_REQUEST", e.message
      else
        server_error e
      end
    end
  end
end
