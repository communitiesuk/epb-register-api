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

  context "when calling the /address-match API endpoint" do
    before do
      OauthStub.token
      WebMock
        .stub_request(
          :post,
          addressing_api_endpoint,
        )
        .to_return(status: 200, body: "sample")

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
  end
end
