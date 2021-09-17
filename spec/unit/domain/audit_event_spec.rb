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
end
