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

  context "when validating that SAP-Version and SAP-Data-Version nodes are correct for version of SAP schema" do
    before do
      allow(Helper::Toggles).to receive(:enabled?)
      allow(Helper::Toggles).to receive(:enabled?).with("register-api-validate-sap-data-version").and_return(true)
      allow(Helper::Toggles).to receive(:enabled?).with("register-api-validate-sap-data-version").and_yield
    end

    context "when passed a non-SAP assessment" do
      it "validates it" do
        expect {
          use_case.execute assessment_xml: valid_xml,
                           schema_name: "RdSAP-Schema-20.0.0",
                           scheme_ids: "1",
                           migrated: true,
                           overidden: false
        }.not_to raise_error
      end
    end

    context "when passed a SAP assessment with an invalid SAP-Version node" do
      let(:bad_sap_version_xml) do
        xml = Nokogiri.XML Samples.xml("SAP-Schema-19.0.0")
        xml.at("SAP-Version").content = "9.90"

        xml.to_s
      end

      it "raises an invalid SAP data version error" do
        expect {
          use_case.execute assessment_xml: bad_sap_version_xml,
                           schema_name: "SAP-Schema-19.0.0",
                           scheme_ids: "1",
                           migrated: true,
                           overidden: false
        }.to raise_error described_class::InvalidSapDataVersionError
      end
    end

    context "when passed a SAP assessment with a valid SAP-Version node" do
      let(:good_sap_version_xml) do
        xml = Nokogiri.XML Samples.xml("SAP-Schema-19.0.0")
        xml.at("SAP-Version").content = "10.2"

        xml.to_s
      end

      it "validates it" do
        expect {
          use_case.execute assessment_xml: good_sap_version_xml,
                           schema_name: "SAP-Schema-19.0.0",
                           scheme_ids: "1",
                           migrated: true,
                           overidden: false
        }.not_to raise_error
      end
    end

    context "when passed a SAP assessment with an invalid SAP-Data-Version node" do
      let(:bad_sap_data_version_xml) do
        xml = Nokogiri.XML Samples.xml("SAP-Schema-19.0.0")
        xml.at("SAP-Data-Version").content = "9.80"

        xml.to_s
      end

      it "raises an invalid SAP data version error" do
        expect {
          use_case.execute assessment_xml: bad_sap_data_version_xml,
                           schema_name: "SAP-Schema-19.0.0",
                           scheme_ids: "1",
                           migrated: true,
                           overidden: false
        }.to raise_error described_class::InvalidSapDataVersionError
      end
    end

    context "when passed a SAP assessment with a valid SAP-Data-Version node" do
      let(:good_sap_data_version_xml) do
        xml = Nokogiri.XML Samples.xml("SAP-Schema-19.0.0")
        xml.at("SAP-Data-Version").content = "10.2"

        xml.to_s
      end

      it "validates it" do
        expect {
          use_case.execute assessment_xml: good_sap_data_version_xml,
                           schema_name: "SAP-Schema-19.0.0",
                           scheme_ids: "1",
                           migrated: true,
                           overidden: false
        }.not_to raise_error
      end
    end

    context "when passed a SAP assessment with a schema not included within the validation list" do
      let(:unvalidated_sap_xml) { Samples.xml("SAP-Schema-17.0") }

      it "validates it" do
        expect {
          use_case.execute assessment_xml: unvalidated_sap_xml,
                           schema_name: "SAP-Schema-17.0",
                           scheme_ids: "1",
                           migrated: true,
                           overidden: false
        }.not_to raise_error
      end
    end
  end

  context "when validating Northern Ireland assessments" do
    let(:rdsap_ni) { Nokogiri.XML(Samples.xml("RdSAP-Schema-NI-20.0.0")) }
    let(:rdsap) { Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0")) }

    before do
      Timecop.freeze(2021, 2, 22, 0, 0, 0)
    end

    after do
      Timecop.return
    end

    it "accepts an NI schema with a BT postcode" do
      expect {
        use_case.execute assessment_xml: rdsap_ni.to_xml,
                         schema_name: "RdSAP-Schema-NI-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.not_to raise_exception
    end

    it "rejects an NI schema without a BT postcode" do
      rdsap_ni.xpath("//*[local-name() = 'Postcode']").each { |node| node.content = "SW1 0AA" }
      expect {
        use_case.execute assessment_xml: rdsap_ni.to_s,
                         schema_name: "RdSAP-Schema-NI-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.to raise_exception UseCase::ValidateAndLodgeAssessment::LodgementRulesException, /must have a property postcode starting with BT/
    end

    it "rejects a BT postcode without an NI Schema" do
      rdsap.xpath("//*[local-name() = 'Postcode']").each { |node| node.content = "BT1 0AA" }
      expect {
        use_case.execute assessment_xml: rdsap.to_s,
                         schema_name: "RdSAP-Schema-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overidden: false
      }.to raise_exception UseCase::ValidateAndLodgeAssessment::LodgementRulesException, /must be lodged with a NI Schema/
    end
  end
end
