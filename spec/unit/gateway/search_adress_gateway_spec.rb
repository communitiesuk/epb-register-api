describe Gateway::SearchAddressGateway, set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  describe "#insert" do
    let(:record) do
      {
        assessment_id: "0000-0000-0000-0000-00001",
        address: {
          address_id: "UPRN-000000000123",
          address_line_1: "22 Acacia Avenue",
          address_line_2: "some place",
          address_line_3: "",
          address_line_4: "",
          town: "Anytown",
          postcode: "AB1 2CD",
        },
      }
    end

    it "saves data to the search address table " do
      search_address = Domain::SearchAddress.new record
      expect { gateway.insert search_address.to_hash }.not_to raise_error
    end
  end
end
