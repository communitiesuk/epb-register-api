describe UseCase::AssessmentMeta do
  context "Extract meta data from the database for an assessment" do
    subject { UseCase::AssessmentMeta.new(gateway) }

    let(:gateway) do
      instance_double("AssessmentMetaGateway")
    end

    before do
      allow(gateway).to receive(:fetch).and_return({ assessment: "0000-0000-0000-0000-0000" })
    end

    it "executes the use case which calls the gateway" do
      expect(subject.execute("0000-0000-0000-0000-0000")).to eq({ assessment: "0000-0000-0000-0000-0000" })
    end
  end
end
