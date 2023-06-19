describe Gateway::SearchAddressGateway, set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new record }

  describe "#insert" do
    let(:record) do
      {
        assessment_id: "0000-0000-0000-0000-00005",
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

    let(:search_address) { Domain::SearchAddress.new record }

    it "saves data to the search address table without error " do
      expect { gateway.insert search_address.to_hash }.not_to raise_error
    end

    it "the saved data is correct" do
      gateway.insert search_address.to_hash
      saved_data = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_search_address")
      expect(saved_data.rows.length).to eq 1
      expect(saved_data[0]["assessment_id"]).to eq "0000-0000-0000-0000-00005"
      expect(saved_data[0]["address"]).to eq "22 acacia avenue some place"
    end

    it "does not duplicate rows" do
      gateway.insert search_address.to_hash
      gateway.insert search_address.to_hash
      saved_data = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_search_address")
      expect(saved_data.rows.length).to eq 1
    end
  end
end
