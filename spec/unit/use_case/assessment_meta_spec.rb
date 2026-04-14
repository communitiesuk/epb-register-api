describe UseCase::AssessmentMeta do
  context "when extracting meta data from the database for an assessment" do
    subject(:use_case) { described_class.new(gateway) }

    let(:gateway) do
      instance_double(Gateway::AssessmentMetaGateway)
    end

    context "when assessment_id has data returned for it" do
      before do
        allow(gateway).to receive(:fetch).and_return({ assessment: "0000-0000-0000-0000-0000" })
      end

      it "executes the use case which calls the gateway" do
        expect(use_case.execute("0000-0000-0000-0000-0000")).to eq({ assessment: "0000-0000-0000-0000-0000" })
      end
    end

    context "when extracting meta data for a Scottish assessment" do
      let(:assessment_id) { "0000-0000-0000-0000-0000" }
      let(:is_scottish) { true }

      let(:expected_result) do
        {
          status: "ENTERED",
          optOut: false,
          createdAt: Date.new(2020, 0o5, 0o4),
          cancelledAt: nil,
          typeOfAssessment: "RdSAP",
          schemaType: "RdSAP-Schema-S-19.0",
          assessmentAddressId: "UPRN-000000000123",
        }
      end

      before do
        allow(gateway).to receive(:fetch).with(assessment_id, is_scottish:).and_return(expected_result)
      end

      it "executes the gateway with the correct arguments" do
        result = use_case.execute("0000-0000-0000-0000-0000", is_scottish:)
        expect(gateway).to have_received(:fetch).with(assessment_id, is_scottish:)
        expect(result).to eq(expected_result)
      end
    end

    context "when the assessment_id has no data returned" do
      before do
        allow(gateway).to receive(:fetch).and_return(nil)
      end

      it "raises an error when there is no data for an assessment" do
        expect { use_case.execute("0000-0000-0000-0000-0001") }.to raise_error(UseCase::AssessmentMeta::NoDataException)
      end
    end
  end
end
