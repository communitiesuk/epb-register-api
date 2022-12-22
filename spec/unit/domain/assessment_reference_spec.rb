describe Domain::AssessmentReference do
  subject(:reference) { described_class.new rrn: }

  context "when an RRN is correctly formed" do
    let(:rrn) { "0000-1111-2222-3333-4444" }

    it "takes an RRN and makes it available" do
      expect(reference.rrn).to eq rrn
    end
  end

  context "when an RRN is incorrectly formed" do
    let(:rrn) { "0000-1111-2222-3333" }

    it "raises an ArgumentError on instantiation" do
      expect { reference }.to raise_error ArgumentError
    end
  end
end
