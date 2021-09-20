describe UseCase::ValidateAndLodgeAssessment do
  subject(:use_case) do
    described_class.new(
      validate_assessment_use_case: validate_assessment_use_case,
      lodge_assessment_use_case: instance_spy(UseCase::LodgeAssessment),
      check_assessor_belongs_to_scheme_use_case: check_assessor_belongs_to_scheme_use_case,
      check_approved_software_use_case: check_approved_software_use_case,
    )
  end

  let(:valid_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

  let(:validate_assessment_use_case) do
    use_case = instance_double(UseCase::ValidateAssessment)
    allow(use_case).to receive(:execute).and_return true

    use_case
  end

  let(:check_assessor_belongs_to_scheme_use_case) do
    use_case = instance_double(UseCase::CheckAssessorBelongsToScheme)
    allow(use_case).to receive(:execute).and_return true

    use_case
  end

  let(:check_approved_software_use_case) do
    use_case = instance_double(UseCase::CheckApprovedSoftware)
    allow(use_case).to receive(:execute).and_return true

    use_case
  end

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

  context "when validating with assessment XML that does not contain approved software" do
    let(:check_approved_software_use_case) do
      use_case = instance_double(UseCase::CheckApprovedSoftware)
      allow(use_case).to receive(:execute).and_return false

      use_case
    end

    before do
      allow(Helper::Toggles).to receive(:enabled?)
      allow(Helper::Toggles).to receive(:enabled?).with("validate-software").and_yield
    end

    it "raises the error SoftwareNotApprovedError" do
      expect {
        use_case.execute assessment_xml: valid_xml,
                         schema_name: "RdSAP-Schema-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.to raise_exception UseCase::ValidateAndLodgeAssessment::SoftwareNotApprovedError
    end

    context "and the migrated flag is true" do
      it "does not raise a SoftwareNotApprovedError", on_potential_false_positives: :nothing do
        expect {
          use_case.execute assessment_xml: valid_xml,
                           schema_name: "RdSAP-Schema-20.0.0",
                           scheme_ids: "1",
                           migrated: true,
                           overidden: false
        }.not_to raise_error
      end
    end
  end
end
