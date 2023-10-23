describe UseCase::FetchActiveSchemesId do
  context "when fetching active schemes scheme ids" do
    subject(:use_case) { described_class.new(schemes_gateway) }

    let(:schemes_gateway) { instance_double(Gateway::SchemesGateway) }
    let(:gateway) { instance_double(Gateway::SchemesGateway) }

    before do
      allow(schemes_gateway).to receive(:fetch_active).and_return([1, 2, 3, 5])
    end

    it "invokes without error" do
      expect { use_case.execute }.not_to raise_error
    end

    it "returns an array of scheme_ids" do
      expect(use_case.execute).to eq [1, 2, 3, 5]
    end
  end
end
