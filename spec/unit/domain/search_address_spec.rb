describe Domain::SearchAddress do
  subject(:object) do
    described_class
  end

  let(:record) do
    {
      assessment_id: "0000-0000-0000-0000-00001",
      address: {
        address_id: "UPRN-000000000123",
        address_line1: "22 Acacia Avenue",
        address_line2: "some place",
        address_line3: "",
        address_line4: "",
        town: "Anytown",
        postcode: "AB1 2CD",
      },
    }
  end

  context "when initializing the object" do
    it "does not raise an error" do
      expect { described_class.new record }.not_to raise_error
    end

    describe "#to_hash" do
      it "returns a hash with the expected keys and values" do
        search_address = described_class.new(record).to_hash
        expect(search_address[:assessment_id]).to eq "0000-0000-0000-0000-00001"
        expect(search_address[:address]).to eq "22 acacia avenue some place"
      end

      it "returns an address without extra spaces when a line is NULL" do
        record[:address][:address_line4] = nil
        search_address = described_class.new(record).to_hash
        expect(search_address[:assessment_id]).to eq "0000-0000-0000-0000-00001"
        expect(search_address[:address]).to eq "22 acacia avenue some place"
      end

      it "returns an address without extra spaces when a line is empty" do
        record[:address][:address_line4] = "another town"
        search_address = described_class.new(record).to_hash
        expect(search_address[:assessment_id]).to eq "0000-0000-0000-0000-00001"
        expect(search_address[:address]).to eq "22 acacia avenue some place another town"
      end
    end
  end
end
