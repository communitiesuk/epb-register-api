describe Domain::AssessmentStatusEvent do
  subject(:object) do
    described_class
  end

  let(:assessment_event) do
    {
      entity_id: "0000-0000-0000-0000-00001",
      event_type: "scottish_opt_out",
      timestamp: Time.new(2013, 1, 1),
    }
  end

  context "when initializing the object" do
    it "does not raise an error" do
      expect { described_class.new(assessment_event: assessment_event) }.not_to raise_error
    end

    describe "#to_hash" do
      it "returns a hash with the expected keys and values" do
        search_address = described_class.new(assessment_event: assessment_event).to_hash
        expect(search_address[:reportRrn]).to eq "0000-0000-0000-0000-00001"
        expect(search_address[:newStatus]).to eq "OPTED OUT"
      end
    end
  end
end
