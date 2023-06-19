describe UseCase::BulkInsertSearchAddress do
  let(:search_address_gateway) { instance_double(Gateway::SearchAddressGateway) }
  let(:use_case) { described_class.new(search_address_gateway) }

  before do
    allow(search_address_gateway).to receive(:bulk_insert)
  end

  describe "#execute" do
    it "is called without error" do
      expect { use_case.execute }.not_to raise_error
    end

    it "calls the bulk insert method on the gateway" do
      use_case.execute
      expect(search_address_gateway).to have_received(:bulk_insert).exactly(1).times
    end
  end
end
