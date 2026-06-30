describe UseCase::FindAssessorsByPostcode do
  subject(:use_case) { described_class.new }

  let(:postcode_result) { { postcode: "N8 8HJ", longitude: 0.2, latitude: 0.1 } }
  let(:postcode_gateway) { instance_double(Gateway::PostcodesGateway) }
  let(:assessor_gateway) { instance_double(Gateway::AssessorsGateway) }

  describe "#execute" do
    before do
      allow(postcode_gateway).to receive(:fetch).with("N8 8HJ", is_scottish: false).and_return([postcode_result])
      allow(assessor_gateway).to receive(:search).with(0.1, 0.2, "domesticSap", is_scottish: false).and_return([])
      allow(Gateway::PostcodesGateway).to receive(:new).and_return(postcode_gateway)
      allow(Gateway::AssessorsGateway).to receive(:new).and_return(assessor_gateway)
      use_case.execute("  n88hj  ", "domesticSap")
    end

    it "formats the postcode before passing it to the postcodes gateway" do
      expect(postcode_gateway).to have_received(:fetch).with("N8 8HJ", is_scottish: false)
    end

    it "passes the postcode result to the assessor gateway" do
      expect(assessor_gateway).to have_received(:search).with(0.1, 0.2, "domesticSap", is_scottish: false)
    end

    it "returns the postcode data returned by the use case" do
      expect(use_case.execute("  n88hj  ", "domesticSap")).to eq({
        data: [],
        search_postcode: "N8 8HJ",
      })
    end

    it "passes a is_scottish to the postcode and assessor gateway" do
      postcode_result = { postcode: "EH1 2NG", longitude: 55.9, latitude: -3.2 }
      allow(postcode_gateway).to receive(:fetch).with("EH1 2NG", is_scottish: true).and_return([postcode_result])
      allow(assessor_gateway).to receive(:search).with(-3.2, 55.9, "scotlandRdsap", is_scottish: true).and_return([])
      use_case.execute("EH1 2NG", "scotlandRdsap", is_scottish: true)

      expect(postcode_gateway).to have_received(:fetch).with("EH1 2NG", is_scottish: true)
      expect(assessor_gateway).to have_received(:search).with(-3.2, 55.9, "scotlandRdsap", is_scottish: true)
    end
  end

  it "raises a ParameterMissing error if the postcode is blank" do
    expect { use_case.execute(nil, "domesticSap") }.to raise_error UseCase::FindAssessorsByPostcode::PostcodeNotValid
  end

  it "raises a PostcodeNotValid error if the postcode is invalid" do
    expect { use_case.execute("X", "domesticSap") }.to raise_error UseCase::FindAssessorsByPostcode::PostcodeNotValid
  end

  it "raises a PostcodeNotRegistered error if the postcode is not found" do
    postcode_gateway = instance_double(Gateway::PostcodesGateway)
    allow(postcode_gateway).to receive(:fetch).with("N0 XXJ", is_scottish: false).and_return([])
    allow(Gateway::PostcodesGateway).to receive(:new).and_return(postcode_gateway)

    expect { use_case.execute("N0 XXJ", "domesticSap") }.to raise_error UseCase::FindAssessorsByPostcode::PostcodeNotRegistered
  end
end
