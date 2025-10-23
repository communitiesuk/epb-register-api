describe Gateway::AddressingApiGateway do
  subject(:gateway) { described_class.new }

  before do
    WebMock.enable!
  end

  after do
    WebMock.disable!
  end

  let(:addressing_api_endpoint) do
    "http://test-addressing.gov.uk/match-address"
  end

  let(:response) do
    [{
      "uprn" => "100023336956",
      "address" => "4 Some Street, LONDON, T4 8AA",
      "confidence" => 99.97436133162083,
    }]
  end

  context "when calling the /match-address API endpoint successfully" do
    before do
      response_body = { "data": response }
      OauthStub.token
      WebMock
       .stub_request(
         :post,
         addressing_api_endpoint,
       )
       .to_return(status: 200, body: response_body.to_json)

      gateway.match_address(postcode: "T4 8AA", address_line_1: "4 Some Street", town: "Town")
    end

    it "posts the addressing API with the right arguments" do
      expect(WebMock).to have_requested(:post, addressing_api_endpoint).with(
        body: {
          postcode: "T4 8AA",
          address_line_1: "4 Some Street",
          address_line_2: "",
          address_line_3: "",
          address_line_4: "",
          town: "Town",
        },
      )
    end

    it "returns the parsed response" do
      result = gateway.match_address(postcode: "T4 8AA", address_line_1: "4 Some Street", town: "Town")
      expect(result).to eq response
    end
  end

  context "when the API call fails with a well formed error response" do
    before do
      OauthStub.token
      WebMock
        .stub_request(
          :post,
          addressing_api_endpoint,
        )
        .to_return(status: 400, body: { error: "Invalid postcode" }.to_json)
    end

    it "raises an error" do
      expect { gateway.match_address(postcode: "T4 8AA", address_line_1: "4 Some Street", town: "Town") }.to raise_error(Errors::ApiResponseError)
    end
  end

  context "when the API call returns 200, but contains no 'data' key in the body" do
    before do
      OauthStub.token
      WebMock
        .stub_request(
          :post,
          addressing_api_endpoint,
        )
        .to_return(status: 200, body: { valid_json: "with no data key" }.to_json)
    end

    it "raises an error" do
      expect { gateway.match_address(postcode: "T4 8AA", address_line_1: "4 Some Street", town: "Town") }.to raise_error(Errors::MalformedResponseError)
    end
  end

  context "when the API call returns successfully but is not a 200 response" do
    before do
      OauthStub.token
      WebMock
        .stub_request(
          :post,
          addressing_api_endpoint,
        )
        .to_return(status: 206, body: { data: "valid body" }.to_json)
    end

    it "raises an error" do
      expect { gateway.match_address(postcode: "T4 8AA", address_line_1: "4 Some Street", town: "Town") }.to raise_error(Errors::MalformedResponseError)
    end
  end

  context "when the API call returns invalid json" do
    before do
      OauthStub.token
      WebMock
        .stub_request(
          :post,
          addressing_api_endpoint,
        )
        .to_return(status: 200, body: "not valid json")
    end

    it "raises an error" do
      expect { gateway.match_address(postcode: "T4 8AA", address_line_1: "4 Some Street", town: "Town") }.to raise_error(Errors::NonJsonResponseError)
    end
  end

  context "when authentication fails" do
    before do
      OauthStub.token
      WebMock
        .stub_request(
          :post,
          addressing_api_endpoint,
        )
        .to_return(status: 401, body: { errors: ["Some auth issue."] }.to_json)
    end

    it "raises an error" do
      expect { gateway.match_address(postcode: "T4 8AA", address_line_1: "4 Some Street", town: "Town") }.to raise_error(Errors::ApiAuthorizationError)
    end
  end
end
