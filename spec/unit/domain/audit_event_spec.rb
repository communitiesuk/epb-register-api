describe Domain::AuditEvent do
  it "validates entity type" do
    expect {
      described_class.new(
        entity_type: :unicorn,
        event_type: :lodgement,
        entity_id: "0000-0000-0000-0000",
      )
    }.to raise_error(ArgumentError, "Invalid entity_type")
  end

  it "validates event type" do
    expect {
      described_class.new(
        entity_type: :assessment,
        event_type: :assessment_exploded,
        entity_id: "0000-0000-0000-0000",
      )
    }.to raise_error(ArgumentError, "Invalid event_type for assessment")
  end

  describe "#valid_assessment_types" do
    it "returns an array of valid assessment events type" do
      expect(described_class.valid_assessment_types).to eq(%i[lodgement opt_out opt_in cancelled address_id_updated])
    end
  end
end
