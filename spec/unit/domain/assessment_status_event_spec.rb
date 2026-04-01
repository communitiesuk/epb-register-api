describe Domain::AssessmentStatusEvent do
  subject(:object) do
    described_class
  end

  let(:assessment_event) do
    {
      entity_id: "0000-0000-0000-0000-0001",
      event_type: "scottish_opt_out",
      timestamp: Time.new(2013, 1, 1),
    }
  end

  let(:expected_result) do
    {
      reportRrn: "0000-0000-0000-0000-0001",
      newStatus: "OPTED OUT",
      timeOfChange: Time.new(2013, 1, 1),
    }
  end

  context "when initializing the object" do
    it "does not raise an error" do
      expect { described_class.new(assessment_event: assessment_event) }.not_to raise_error
    end

    describe "#to_hash" do
      it "returns a hash with the expected keys and values" do
        assessment_status_event = described_class.new(assessment_event: assessment_event).to_hash
        expect(assessment_status_event).to eq expected_result
      end

      it "return an unknown event type" do
        unknown_event = {
          entity_id: "0000-0000-0000-0000-0001",
          event_type: "undefined_event",
          timestamp: Time.new(2013, 1, 1),
        }
        expected_result = {
          reportRrn: "0000-0000-0000-0000-0001",
          newStatus: "unknown event",
          timeOfChange: Time.new(2013, 1, 1),
        }
        assessment_status_event = described_class.new(assessment_event: unknown_event).to_hash
        expect(assessment_status_event).to eq expected_result
      end
    end
  end
end
