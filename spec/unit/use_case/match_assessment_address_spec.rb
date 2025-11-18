describe UseCase::MatchAssessmentAddress do
  subject(:use_case) do
    described_class.new(
      addressing_api_gateway:,
      assessments_address_id_gateway:,
    )
  end

  let(:addressing_api_gateway) { instance_double(Gateway::AddressingApiGateway) }
  let(:assessments_address_id_gateway) { instance_double(Gateway::AssessmentsAddressIdGateway) }

  let(:assessment_id) { "0000-0000-0000-0000-0001" }
  let(:args) do
    {
      address_line_1: "1 Some Street",
      address_line_2: "Some Area",
      address_line_3: "Some County",
      address_line_4: nil,
      town: "Whitbury",
      postcode: "SW1A 2AA",
    }
  end
  let(:uprn) { "199990144" }
  let(:confidence) { 99.9 }

  describe "#execute" do
    before do
      allow(assessments_address_id_gateway).to receive(:update_matched_address_id)
    end

    context "when there is only a single match returned" do
      before do
        allow(addressing_api_gateway).to receive(:match_address).with(**args).and_return(
          [{ "uprn" => uprn, "address" => "1 Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => confidence }],
        )
        use_case.execute(assessment_id:, **args)
      end

      it "calls the addressing api gateway with the correct arguments" do
        expect(addressing_api_gateway).to have_received(:match_address).once.with(**args)
      end

      it "calls the address id gateway with the correct arguments" do
        expect(assessments_address_id_gateway).to have_received(:update_matched_address_id).once.with(assessment_id, uprn, confidence)
      end
    end

    context "when are no results returned" do
      before do
        allow(addressing_api_gateway).to receive(:match_address).with(**args).and_return([])
        use_case.execute(assessment_id:, **args)
      end

      it "updates the matched_address_id as none" do
        expect(assessments_address_id_gateway).to have_received(:update_matched_address_id).once.with(assessment_id, "none", nil)
      end
    end

    context "when multiple matches are returned with different confidence" do
      before do
        allow(addressing_api_gateway).to receive(:match_address).with(**args).and_return(
          [
            { "uprn" => "199990129", "address" => "11 Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "9.0" },
            { "uprn" => "199990144", "address" => "12 Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "90.9" },

          ],
        )
        use_case.execute(assessment_id:, **args)
      end

      it "updates the matched_address_id to the uprn with the most confidence" do
        expect(assessments_address_id_gateway).to have_received(:update_matched_address_id).once.with(assessment_id, "199990144", "90.9")
      end
    end

    context "when multiple matches are returned with the same confidence" do
      before do
        allow(addressing_api_gateway).to receive(:match_address).with(**args).and_return(
          [
            { "uprn" => "199990129", "address" => "1A Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "46.2" },
            { "uprn" => "199990144", "address" => "1B Some Street, Some Area, Some County, Whitbury, SW1A 2AA", "confidence" => "46.2" },
          ],
        )
        use_case.execute(assessment_id:, **args)
      end

      it "updates the matched_address_id as unknown with the confidence value" do
        expect(assessments_address_id_gateway).to have_received(:update_matched_address_id).once.with(assessment_id, "unknown", "46.2")
      end
    end
  end
end
