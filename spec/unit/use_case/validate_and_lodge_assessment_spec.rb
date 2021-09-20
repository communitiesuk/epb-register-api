describe UseCase::ValidateAndLodgeAssessment do
  subject(:use_case) do
    described_class.new(
      validate_assessment_use_case: instance_double(UseCase::ValidateAssessment),
      lodge_assessment_use_case: instance_double(UseCase::LodgeAssessment),
      check_assessor_belongs_to_scheme_use_case: instance_double(UseCase::CheckAssessorBelongsToScheme),
    )
  end

  let(:valid_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

  context "when validating an invalid schema name" do
    it "raises the error SchemaNotAccepted" do
      expect {
        use_case.execute assessment_xml: valid_xml,
                         schema_name: "Non-existent-RdSAP-Schema-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.to raise_exception(
        UseCase::ValidateAndLodgeAssessment::SchemaNotSupportedException,
      )
    end
  end

  context "when validating without having been passed a schema name" do
    it "raises the error SchemaNotDefined" do
      expect {
        use_case.execute assessment_xml: valid_xml,
                         schema_name: nil,
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.to raise_exception(
        UseCase::ValidateAndLodgeAssessment::SchemaNotDefined,
      )
    end
  end
end
