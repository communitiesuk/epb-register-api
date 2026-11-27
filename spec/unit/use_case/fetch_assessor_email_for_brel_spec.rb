describe UseCase::FetchAssessorEmailForBrel do
  subject(:use_case) { described_class.new(assessor_gateway:) }

  let(:assessor_gateway) do
    instance_double(Gateway::AssessorsGateway)
  end

  context "when the request returns an assessor with the correct qualification" do
    before do
      allow(assessor_gateway).to receive(:fetch).with("an id").and_return(Domain::Assessor.new(email: "test@test.com", domestic_sap_qualification: "ACTIVE"))
    end

    it "returns the assessor email" do
      expect(use_case.execute("an id")).to eq({ email: "test@test.com" })
    end
  end

  context "when the request returns an assessor with the correct qualification but no email" do
    before do
      allow(assessor_gateway).to receive(:fetch).with("an id").and_return(Domain::Assessor.new(email: nil, domestic_sap_qualification: "ACTIVE"))
    end

    it "returns the assessor body with nil for the email" do
      expect(use_case.execute("an id")).to eq({ email: nil })
    end
  end

  context "when the request does not return an assessor" do
    before do
      allow(assessor_gateway).to receive(:fetch).with("an id").and_return(nil)
    end

    it "returns an empty response" do
      expect(use_case.execute("an id")).to eq({})
    end
  end

  context "when the request returns an assessor without the correct qualification" do
    before do
      allow(assessor_gateway).to receive(:fetch).with("an id").and_return(Domain::Assessor.new(email: "test@test.com", domestic_sap_qualification: "SUSPENDED"))
    end

    it "returns an empty response" do
      expect(use_case.execute("an id")).to eq({})
    end
  end
end
