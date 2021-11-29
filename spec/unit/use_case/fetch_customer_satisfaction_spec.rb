describe UseCase::FetchCustomerSatisfaction do
  context "when extracting customer satisfaction data " do
    subject(:use_case) { described_class.new(stats_gateway) }

    let(:stats_gateway)  do
      instance_double(Gateway::CustomerSatisfactionGateway)
    end

    let(:data) do
      [{
        "stats_date" => "2021-10-01",
        "very_satisfied" => 20,
        "satisfied" => 14,
        "neither" => 10,
        "dissatisfied" => 21,
        "very_dissatisfied" => 32,
      }]
    end

    before do
      allow(stats_gateway).to receive(:fetch).and_return(data)
    end

    it "call the gateway once " do
      use_case.execute
      expect(stats_gateway).to have_received(:fetch).exactly(1).times
    end

    it "call the gateway to extract the data " do
      expect(use_case.execute).to eq(data)
    end
  end
end
