describe UseCase::ValidateAndLodgeAssessment do
  subject(:use_case) { described_class.new }

  let(:valid_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

  context "when validating an invalid schema name" do
    it "raises the error SchemaNotAccepted" do
      expect {
        use_case.execute(
          valid_xml,
          "Non-existent-RdSAP-Schema-20.0.0",
          "1",
          false,
          false,
        )
      }.to raise_exception(
        UseCase::ValidateAndLodgeAssessment::SchemaNotSupportedException,
      )
    end

    it "raises the error SchemaNotDefined" do
      expect {
        use_case.execute(valid_xml, nil, "1", false, false)
      }.to raise_exception(
        UseCase::ValidateAndLodgeAssessment::SchemaNotDefined,
      )
    end
  end
end
