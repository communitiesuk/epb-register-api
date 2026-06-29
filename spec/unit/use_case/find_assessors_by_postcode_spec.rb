describe UseCase::FindAssessorsByPostcode do
  subject(:use_case) { described_class.new }

  it "returns the postcode data returned by the usecase" do
    postcode_result = { postcode: "N8 8HJ", longitude: 0.2, latitude: 0.1 }
    postcode_gateway = instance_double(Gateway::PostcodesGateway)
    allow(postcode_gateway).to receive(:fetch).with("N8 8HJ", is_scottish: false).and_return([postcode_result])

    assessor_gateway = instance_double(Gateway::AssessorsGateway)
    allow(assessor_gateway).to receive(:search).with(0.1, 0.2, "qualification", is_scottish: false).and_return([])

    allow(Gateway::PostcodesGateway).to receive(:new).and_return(postcode_gateway)
    allow(Gateway::AssessorsGateway).to receive(:new).and_return(assessor_gateway)

    expect(use_case.execute("N8 8HJ", "qualification")).to eq({
      data: [],
      search_postcode: "N8 8HJ",
    })
  end

  it "formats a postcode before passing it to the gateway" do
    postcode_result = { postcode: "N8 8HJ", longitude: 0.2, latitude: 0.1 }
    postcode_gateway = instance_double(Gateway::PostcodesGateway)
    allow(postcode_gateway).to receive(:fetch).with("N8 8HJ", is_scottish: false).and_return([postcode_result])

    assessor_gateway = instance_double(Gateway::AssessorsGateway)
    allow(assessor_gateway).to receive(:search).with(0.1, 0.2, "qualification", is_scottish: false).and_return([])

    allow(Gateway::PostcodesGateway).to receive(:new).and_return(postcode_gateway)
    allow(Gateway::AssessorsGateway).to receive(:new).and_return(assessor_gateway)

    expect(use_case.execute("n88hj", "qualification")).to eq({
      data: [],
      search_postcode: "N8 8HJ",
    })
  end

  it "removes additional white space from a postcode before passing it to the gateway" do
    postcode_result = { postcode: "N8 8HJ", longitude: 0.2, latitude: 0.1 }
    postcode_gateway = instance_double(Gateway::PostcodesGateway)
    allow(postcode_gateway).to receive(:fetch).with("N8 8HJ", is_scottish: false).and_return([postcode_result])

    assessor_gateway = instance_double(Gateway::AssessorsGateway)
    allow(assessor_gateway).to receive(:search).with(0.1, 0.2, "qualification", is_scottish: false).and_return([])

    allow(Gateway::PostcodesGateway).to receive(:new).and_return(postcode_gateway)
    allow(Gateway::AssessorsGateway).to receive(:new).and_return(assessor_gateway)

    expect(use_case.execute("  N8  8HJ  ", "qualification")).to eq({
      data: [],
      search_postcode: "N8 8HJ",
    })
  end

  it "passes a is_scottish to the postcode and assessor gateway" do
    postcode_result = { postcode: "N8 8HJ", longitude: 0.2, latitude: 0.1 }
    postcode_gateway = instance_double(Gateway::PostcodesGateway)
    allow(postcode_gateway).to receive(:fetch).with("N8 8HJ", is_scottish: true).and_return([postcode_result])

    assessor_gateway = instance_double(Gateway::AssessorsGateway)
    allow(assessor_gateway).to receive(:search).with(0.1, 0.2, "qualification", is_scottish: true).and_return([])

    allow(Gateway::PostcodesGateway).to receive(:new).and_return(postcode_gateway)
    allow(Gateway::AssessorsGateway).to receive(:new).and_return(assessor_gateway)

    expect(use_case.execute("N8 8HJ", "qualification", is_scottish: true)).to eq({
      data: [],
      search_postcode: "N8 8HJ",
    })
  end

  it "raises a ParameterMissing error if the postcode is blank" do
    expect { use_case.execute(nil, nil) }.to raise_error UseCase::FindAssessorsByPostcode::PostcodeNotValid
  end

  it "raises a PostcodeNotValid error if the postcode is invalid" do
    expect { use_case.execute("X", nil) }.to raise_error UseCase::FindAssessorsByPostcode::PostcodeNotValid
  end

  it "raises a PostcodeNotRegistered error if the postcode is not found" do
    postcode_gateway = instance_double(Gateway::PostcodesGateway)
    allow(postcode_gateway).to receive(:fetch).with("N8 8HJ", is_scottish: false).and_return([])
    allow(Gateway::PostcodesGateway).to receive(:new).and_return(postcode_gateway)

    expect { use_case.execute("N8 8HJ", nil) }.to raise_error UseCase::FindAssessorsByPostcode::PostcodeNotRegistered
  end
end
