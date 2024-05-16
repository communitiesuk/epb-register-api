describe Gateway::CountryGateway do
  subject(:gateway) { described_class.new }

  before do
    add_countries
  end

  describe "#fetch_countries" do
    let(:result) { gateway.fetch_countries }

    let(:data) do
      [{ country_code: "ENG", address_base_country_code: "[\"E\"]", country_id: 1, country_name: "England" },
       { country_code: "EAW", address_base_country_code: "[\"E\", \"W\"]", country_id: 2, country_name: "England and Wales" },
       { country_code: "UKN", address_base_country_code: "{}", country_id: 3, country_name: "Unknown" },
       { country_code: "NIR", address_base_country_code: "[\"N\"]", country_id: 4, country_name: "Northern Ireland" },
       { country_code: "SCT", address_base_country_code: "[\"S\"]", country_id: 5, country_name: "Scotland" },
       { country_code: "", address_base_country_code: "[\"L\"]", country_id: 6, country_name: "Channel Islands" }]
    end

    it "returns all the expected data points" do
      expect(result).to eq data
    end
  end
end
