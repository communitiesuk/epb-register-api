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

  context "when the API call fails with an error" do
    before do
      OauthStub.token
      WebMock
      .stub_request(
        :post,
        addressing_api_endpoint,
      )
      .to_return(status: 500, body: { error: "Invalid postcode" }.to_json)
    end

    it "raises an error" do
      expect { gateway.match_address(postcode: "T4 8AA", address_line_1: "4 Some Street", town: "Town") }.to raise_error(Boundary::InternalServerError)
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
      expect { gateway.match_address(postcode: "T4 8AA", address_line_1: "4 Some Street", town: "Town") }.to raise_error(Boundary::InternalServerError)
    end
  end
end
