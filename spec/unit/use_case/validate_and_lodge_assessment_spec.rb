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
    it "raises the error SchemaNotSupportedException" do
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
      allow(Helper::Toggles).to receive(:enabled?).with("validate-software", default: false).and_yield
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

  context "when validating assessment XML that is not from the current version of a schema" do
    let(:old_schema_xml) { Samples.xml "RdSAP-Schema-19.0" }

    after do
      Timecop.return
    end

    it "raises a SchemaNotSupportedException" do
      Timecop.freeze(2022, 0o5, 13, 0, 0, 0)
      expect {
        use_case.execute assessment_xml: old_schema_xml,
                         schema_name: "RdSAP-Schema-19.0",
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.to raise_error UseCase::ValidateAndLodgeAssessment::SchemaNotSupportedException
    end
  end

  context "when validating assessment XML that is from the current version of a schema" do
    let(:valid_xml) { Samples.xml "SAP-Schema-19.0.0" }

    after do
      Timecop.return
    end

    it "validates SAP Schema version 19 " do
      Timecop.freeze(2022, 0o5, 13, 0, 0, 0)
      expect {
        use_case.execute assessment_xml: valid_xml,
                         schema_name: "SAP-Schema-19.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.not_to raise_exception
    end

    it "validates SAP Schema version 18 " do
      valid_xml = Samples.xml "SAP-Schema-18.0.0"
      Timecop.freeze(2021, 2, 22, 0, 0, 0)
      expect {
        use_case.execute assessment_xml: valid_xml,
                         schema_name: "SAP-Schema-18.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.not_to raise_exception
    end
  end

  context "when validation an assessment is in Northern Ireland" do
    let(:valid_xml) { Nokogiri.XML(Samples.xml("RdSAP-Schema-NI-20.0.0")) }

    before do
      Timecop.freeze(2021, 2, 22, 0, 0, 0)
    end

    after do
      Timecop.return
    end

    it "accepts an NI assessment with a BT postcode regardless of case ", aggregate_failures: true do
      expect {
        use_case.execute assessment_xml: valid_xml.to_xml,
                         schema_name: "RdSAP-Schema-NI-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.not_to raise_exception

      valid_xml.xpath("//*[local-name() = 'Postcode']").each { |node| node.content = "bt10 0AA" }
      expect {
        use_case.execute assessment_xml: valid_xml.to_xml,
                         schema_name: "RdSAP-Schema-NI-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.not_to raise_exception

      valid_xml.xpath("//*[local-name() = 'Postcode']").each { |node| node.content = " bt9 1CC" }
      expect {
        use_case.execute assessment_xml: valid_xml.to_xml,
                         schema_name: "RdSAP-Schema-NI-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.not_to raise_exception
    end

    it "raises an error when postcode is not in BT" do
      valid_xml.xpath("//*[local-name() = 'Postcode']").each { |node| node.content = "SW1 0AA" }
      expect {
        use_case.execute assessment_xml: valid_xml.to_s,
                         schema_name: "RdSAP-Schema-NI-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.to raise_exception UseCase::ValidateAndLodgeAssessment::NiAssessmentInvalidPostcode
    end
  end
end
