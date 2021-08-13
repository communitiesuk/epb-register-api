describe UseCase::AssessmentMeta do
  context "Extract meta data from the database for an assessment" do
    subject { described_class.new(gateway) }

    let(:gateway) do
      instance_double(Gateway::AssessmentMetaGateway)
    end

    context "when assessment_id has data returned for it" do
      before do
        allow(gateway).to receive(:fetch).and_return({ assessment: "0000-0000-0000-0000-0000" })
      end

      it "executes the use case which calls the gateway" do
        expect(subject.execute("0000-0000-0000-0000-0000")).to eq({ assessment: "0000-0000-0000-0000-0000" })
      end
    end

    context "when the assessment_id has no data returned" do
      before do
        allow(gateway).to receive(:fetch).and_return(nil)
      end

      it "raises an error when there is no data for an assessment" do
        expect { subject.execute("0000-0000-0000-0000-0001") }.to raise_error(UseCase::AssessmentMeta::NoDataException)
      end
    end
  end
end
