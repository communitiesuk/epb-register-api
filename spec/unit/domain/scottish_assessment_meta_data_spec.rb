describe Domain::ScottishAssessmentMetaData do
  subject(:object) do
    described_class
  end

  let(:meta_data) do
    {
      assessment_address_id: "UPRN-000000000123",
      cancelled_at: nil,
      opt_out: false,
      not_for_issue_at: nil,
      type_of_assessment: "RdSAP",
      schema_type: "RdSAP-Schema-S-19.0",
      created_at: Date.new(2020, 0o5, 0o4),
      date_of_expiry: Date.new(2030, 0o5, 0o3),
      hashed_assessment_id: "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
      country_id: 1,
      green_deal: false,
    }
  end

  let(:expected_result) do
    {
      status: "ENTERED",
      optOut: false,
      createdAt: Date.new(2020, 0o5, 0o4),
      cancelledAt: nil,
      typeOfAssessment: "RdSAP",
      schemaType: "RdSAP-Schema-S-19.0",
      propertyId: "UPRN-000000000123",
    }
  end

  context "when initializing the object" do
    it "does not raise an error" do
      expect { described_class.new(meta_data:) }.not_to raise_error
    end

    describe "#to_hash" do
      it "returns a hash with the expected keys and values" do
        assessment_status_event = described_class.new(meta_data:).to_hash
        expect(assessment_status_event).to eq expected_result
      end

      context "when a certificate is expired" do
        before do
          meta_data[:date_of_expiry] = Date.new(2020, 0o5, 0o4)
          expected_result[:status] = "EXPIRED"
        end

        it "returns the hash with an expired status" do
          assessment_status_event = described_class.new(meta_data:).to_hash
          expect(assessment_status_event).to eq expected_result
        end
      end

      context "when a certificate is marked as cancelled" do
        before do
          meta_data[:cancelled_at] = Date.new(2020, 0o5, 0o4)
          expected_result[:status] = "CANCELLED"
          expected_result[:cancelledAt] = Date.new(2020, 0o5, 0o4)
        end

        it "returns the hash with an cancelled status and date" do
          assessment_status_event = described_class.new(meta_data:).to_hash
          expect(assessment_status_event).to eq expected_result
        end
      end

      context "when a certificate is marked as not for issue" do
        before do
          meta_data[:not_for_issue_at] = Date.new(2020, 0o5, 0o4)
          expected_result[:status] = "CANCELLED"
          expected_result[:cancelledAt] = Date.new(2020, 0o5, 0o4)
        end

        it "returns the hash with an cancelled status and date" do
          assessment_status_event = described_class.new(meta_data:).to_hash
          expect(assessment_status_event).to eq expected_result
        end
      end
    end
  end
end
