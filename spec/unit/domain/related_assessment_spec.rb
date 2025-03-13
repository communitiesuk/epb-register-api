describe Domain::RelatedAssessment do
  let(:domain) { described_class.new(**arguments) }

  let(:arguments) do
    {
      assessment_id: "0000-0000-0000-0000-0001",
      assessment_status: "ENTERED",
      assessment_type: "RdSAP",
      assessment_expiry_date: Time.new(2030, 0o1, 30).utc.to_date,
      opt_out: false,
    }
  end

  let(:expected_data) do
    {
      assessment_id: "0000-0000-0000-0000-0001",
      assessment_status: "ENTERED",
      assessment_type: "RdSAP",
      assessment_expiry_date: "2030-01-30",
      opt_out: false,
    }
  end

  it "returns a domain object" do
    expect(domain).to be_an_instance_of described_class
  end

  describe "#to_hash" do
    it "returns the expected data" do
      expect(domain.to_hash).to eq(expected_data)
    end
  end
end
