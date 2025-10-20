module Gateway
  class AddressingApiGateway
    def initialize
      @addressing_client = Auth::HttpClient.new ENV["EPB_AUTH_CLIENT_ID"],
                                                ENV["EPB_AUTH_CLIENT_SECRET"],
                                                ENV["EPB_AUTH_SERVER"],
                                                ENV["EPB_ADDRESSING_URL"],
                                                OAuth2::Client
    end

    def match_address(postcode:, address_line_1:, town:, address_line_2: "", address_line_3: "", address_line_4: "")
      body = {
        postcode: postcode,
        address_line_1: address_line_1,
        address_line_2: address_line_2,
        address_line_3: address_line_3,
        address_line_4: address_line_4,
        town: town,
      }.to_json

      @addressing_client.post("/match-address") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = body
      end
    end
  end
end
