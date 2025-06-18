describe UseCase::ValidateAndLodgeAssessment do
  subject(:use_case) do
    described_class.new(
      validate_assessment_use_case:,
      lodge_assessment_use_case:,
      check_assessor_belongs_to_scheme_use_case:,
      check_approved_software_use_case:,
      country_use_case:,
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

  let(:lodge_assessment_use_case) do
    instance_spy(UseCase::LodgeAssessment)
  end

  let(:country_use_case) do
    instance_double(UseCase::GetCountryForCandidateLodgement)
  end

  context "when validating an invalid schema name" do
    it "raises the error SchemaNotSupportedException" do
      expect {
        use_case.execute assessment_xml: valid_xml,
                         schema_name: "Non-existent-RdSAP-Schema-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overridden: false
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
                         overridden: false
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

    it "raises the error SoftwareNotApprovedError" do
      expect {
        use_case.execute assessment_xml: valid_xml,
                         schema_name: "RdSAP-Schema-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overridden: false
      }.to raise_exception UseCase::ValidateAndLodgeAssessment::SoftwareNotApprovedError
    end

    context "and the migrated flag is true" do
      it "does not raise a SoftwareNotApprovedError", on_potential_false_positives: :nothing do
        expect {
          use_case.execute assessment_xml: valid_xml,
                           schema_name: "RdSAP-Schema-20.0.0",
                           scheme_ids: "1",
                           migrated: true,
                           overridden: false
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
                         overridden: false
      }.to raise_error UseCase::ValidateAndLodgeAssessment::SchemaNotSupportedException
    end
  end

  context "when validating assessment XML that is from the current version of a schema" do
    after do
      Timecop.return
    end

    before do
      allow(country_use_case).to receive(:execute).and_return Domain::CountryLookup.new(country_codes: [:W])
    end

    it "validates SAP Schema version 19.1.0" do
      valid_xml = Samples.xml "SAP-Schema-19.1.0"
      Timecop.freeze(2022, 0o5, 13, 0, 0, 0)
      expect {
        use_case.execute assessment_xml: valid_xml,
                         schema_name: "SAP-Schema-19.1.0",
                         scheme_ids: "1",
                         migrated: false,
                         overridden: false
      }.not_to raise_exception
    end

    it "validates SAP Schema version 19.0.0" do
      valid_xml = Samples.xml "SAP-Schema-19.0.0"
      Timecop.freeze(2022, 0o5, 13, 0, 0, 0)
      expect {
        use_case.execute assessment_xml: valid_xml,
                         schema_name: "SAP-Schema-19.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overridden: false
      }.not_to raise_exception
    end

    it "validates SAP Schema version 18" do
      valid_xml = Samples.xml "SAP-Schema-18.0.0"
      Timecop.freeze(2021, 2, 22, 0, 0, 0)
      expect {
        use_case.execute assessment_xml: valid_xml,
                         schema_name: "SAP-Schema-18.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overridden: false
      }.not_to raise_exception
    end

    it "validates RdSAP Schema version 21.0.0" do
      valid_xml = Samples.xml "RdSAP-Schema-21.0.0"
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("VALID_DOMESTIC_SCHEMAS").and_return("RdSAP-Schema-21.0.0")
      Timecop.freeze(2023, 12, 2, 0, 0, 0)
      expect {
        use_case.execute assessment_xml: valid_xml,
                         schema_name: "RdSAP-Schema-21.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overridden: false
      }.not_to raise_exception
    end

    it "validates RdSAP Schema version 21.0.1" do
      valid_xml = Samples.xml "RdSAP-Schema-21.0.1"
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("VALID_DOMESTIC_SCHEMAS").and_return("RdSAP-Schema-21.0.1")
      Timecop.freeze(2025, 05, 2, 0, 0, 0)
      expect {
        use_case.execute assessment_xml: valid_xml,
                         schema_name: "RdSAP-Schema-21.0.1",
                         scheme_ids: "1",
                         migrated: false,
                         overridden: false
      }.not_to raise_exception
    end
  end

  context "when validating that SAP-Version and SAP-Data-Version nodes are correct for version of SAP schema" do
    context "when passed a non-SAP assessment" do
      it "validates it" do
        expect {
          use_case.execute assessment_xml: valid_xml,
                           schema_name: "RdSAP-Schema-20.0.0",
                           scheme_ids: "1",
                           migrated: true,
                           overridden: false
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
                           overridden: false
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
                           overridden: false
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
                           overridden: false
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
                           overridden: false
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
                           overridden: false
        }.not_to raise_error
      end
    end
  end

  context "when given a SAP assessment with a 10.2 version and an assessment with a Welsh location" do
    let(:welsh_sap_10_2_xml) do
      xml = Nokogiri.XML Samples.xml("SAP-Schema-19.0.0")
      xml.xpath("//*[local-name() = 'Postcode']").each { |node| node.content = "CF10 1EP" }
      xml.to_s
    end

    it "does not raise an error" do
      expect {
        use_case.execute assessment_xml: welsh_sap_10_2_xml,
                         schema_name: "SAP-Schema-19.0.0",
                         scheme_ids: "1",
                         migrated: true,
                         overridden: false
      }.not_to raise_error
    end
  end

  context "when validating Northern Ireland assessments" do
    let(:rdsap_ni_21) { Nokogiri.XML(Samples.xml("RdSAP-Schema-NI-21.0.0")) }
    let(:rdsap_ni) { Nokogiri.XML(Samples.xml("RdSAP-Schema-NI-20.0.0")) }
    let(:rdsap) { Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0")) }

    before do
      allow(country_use_case).to receive(:execute).and_return Domain::CountryLookup.new(country_codes: [:W])
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
                         overridden: false
      }.not_to raise_exception
    end

    it "rejects an NI schema without a BT postcode" do
      rdsap_ni.xpath("//*[local-name() = 'Postcode']").each { |node| node.content = "SW1 0AA" }
      expect { \
        use_case.execute assessment_xml: rdsap_ni.to_s,
                         schema_name: "RdSAP-Schema-NI-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overridden: false
      }.to raise_exception UseCase::ValidateAndLodgeAssessment::LodgementRulesException, /must have a property postcode starting with BT/
    end

    it "rejects a BT postcode without an NI Schema" do
      rdsap.xpath("//*[local-name() = 'Postcode']").each { |node| node.content = "BT4 3SR" }
      expect {
        use_case.execute assessment_xml: rdsap.to_s,
                         schema_name: "RdSAP-Schema-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overridden: false
      }.to raise_exception UseCase::ValidateAndLodgeAssessment::LodgementRulesException, /must be lodged with a NI Schema/
    end

    it "accepts a RdSAP NI 21 schema" do
      expect {
        use_case.execute assessment_xml: rdsap_ni_21.to_xml,
                         schema_name: "RdSAP-Schema-NI-21.0.0",
                         scheme_ids: "1",
                         migrated: true,
                         overridden: false
      }.not_to raise_exception
    end
  end

  context "when trying to override a rule that cannot be overridden" do
    context "with dates in the future" do
      let(:cepc) { Nokogiri.XML(Samples.xml("CEPC-8.0.0", "cepc")) }

      before do
        allow(country_use_case).to receive(:execute).and_return Domain::CountryLookup.new(country_codes: [:E])
        Timecop.freeze(2019, 2, 22, 0, 0, 0)
      end

      after do
        Timecop.return
      end

      it "raises a NotOverridableLodgementRuleError error" do
        expect {
          use_case.execute assessment_xml: cepc.to_s,
                           schema_name: "CEPC-8.0.0",
                           scheme_ids: "1",
                           migrated: false,
                           overridden: true
        }.to raise_exception UseCase::ValidateAndLodgeAssessment::NotOverridableLodgementRuleError
      end
    end

    context "with a completion date later than the registration date (breaking COMPLETION_DATE_LATER_THAN_REGISTRATION_DATE rule)" do
      let(:rdsap) do
        xml = Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
        xml.at("Completion-Date").content = "2020-06-04" # date after the registration date in the fixture document
        xml
      end

      before do
        allow(country_use_case).to receive(:execute).and_return Domain::CountryLookup.new(country_codes: [:W])
        Timecop.freeze(2021, 2, 22, 0, 0, 0)
      end

      after do
        Timecop.return
      end

      it "raises a NotOverridableLodgementRuleError error" do
        expect {
          use_case.execute assessment_xml: rdsap.to_s,
                           schema_name: "RdSAP-Schema-20.0.0",
                           scheme_ids: "1",
                           migrated: false,
                           overridden: true
        }.to raise_exception UseCase::ValidateAndLodgeAssessment::NotOverridableLodgementRuleError
      end
    end

    context "with dates in the future (breaking DATES_CANT_BE_IN_FUTURE rule)" do
      let(:rdsap) do
        Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
      end

      before do
        allow(country_use_case).to receive(:execute).and_return Domain::CountryLookup.new(country_codes: [:W])
        Timecop.freeze(2020, 5, 3, 0, 0, 0) # Fixture has dates of 2020-05-04; this is the day before.
      end

      after do
        Timecop.return
      end

      it "raises a NotOverridableLodgementRuleError error" do
        expect {
          use_case.execute assessment_xml: rdsap.to_s,
                           schema_name: "RdSAP-Schema-20.0.0",
                           scheme_ids: "1",
                           migrated: false,
                           overridden: true
        }.to raise_exception UseCase::ValidateAndLodgeAssessment::NotOverridableLodgementRuleError
      end
    end

    context "with inspection date later than the completion date (breaking INSPECTION_DATE_LATER_THAN_COMPLETION_DATE rule)" do
      let(:rdsap) do
        xml = Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
        xml.at("Inspection-Date").content = "2020-06-04" # date after the registration date in the fixture document
        xml
      end

      before do
        allow(country_use_case).to receive(:execute).and_return Domain::CountryLookup.new(country_codes: [:W])
        Timecop.freeze(2021, 2, 22, 0, 0, 0)
      end

      after do
        Timecop.return
      end

      it "raises a NotOverridableLodgementRuleError error" do
        expect {
          use_case.execute assessment_xml: rdsap.to_s,
                           schema_name: "RdSAP-Schema-20.0.0",
                           scheme_ids: "1",
                           migrated: false,
                           overridden: true
        }.to raise_exception UseCase::ValidateAndLodgeAssessment::NotOverridableLodgementRuleError
      end
    end

    context "with inspection date later than registration date for non-domestic certificates (breaking the INSPECTION_DATE_LATER_THAN_REGISTRATION_DATE rule)" do
      let(:cepc) do
        xml = Nokogiri.XML(Samples.xml("CEPC-8.0.0", "cepc"))
        xml.at("//CEPC:Inspection-Date").content = "2020-06-14"
        xml
      end

      before do
        allow(country_use_case).to receive(:execute).and_return Domain::CountryLookup.new(country_codes: [:E])
        Timecop.freeze(2022, 12, 22, 0, 0, 0)
        allow(Helper::Toggles).to receive(:enabled?)
      end

      after do
        Timecop.return
      end

      it "raises a NotOverridableLodgmentRuleError error" do
        expect {
          use_case.execute assessment_xml: cepc.to_s,
                           schema_name: "CEPC-8.0.0",
                           scheme_ids: "1",
                           migrated: false,
                           overridden: true
        }.to raise_exception UseCase::ValidateAndLodgeAssessment::NotOverridableLodgementRuleError
      end
    end
  end

  context "when lodging the assessment notifies an ActiveRecord::StatementInvalid error" do
    let(:rdsap) do
      Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
    end

    before do
      allow(country_use_case).to receive(:execute).and_return Domain::CountryLookup.new(country_codes: [:W])
      allow(lodge_assessment_use_case).to receive(:execute).and_raise(ActiveRecord::StatementInvalid)
      Timecop.freeze(2021, 2, 22, 0, 0, 0)
    end

    after do
      Timecop.return
    end

    it "raises a DatabaseWriteError" do
      expect {
        use_case.execute assessment_xml: rdsap.to_s,
                         schema_name: "RdSAP-Schema-20.0.0",
                         scheme_ids: "1",
                         migrated: false,
                         overridden: true
      }.to raise_exception UseCase::ValidateAndLodgeAssessment::DatabaseWriteError
    end
  end

  context "when checking the country of the assessment" do
    let(:welsh_sap_10_2_xml) do
      xml = Nokogiri.XML Samples.xml("SAP-Schema-19.0.0")
      xml.xpath("//*[local-name() = 'Postcode']").each { |node| node.content = "CF10 1EP" }
      xml.to_s
    end

    let(:country_domain) do
      Domain::CountryLookup.new(country_codes: [:W])
    end

    before do
      Timecop.freeze(2022, 0o5, 13, 0, 0, 0)
      allow(country_use_case).to receive(:execute).and_return country_domain
    end

    after do
      Timecop.return
    end

    it "executes the county for candidate assessment use case" do
      use_case.execute assessment_xml: welsh_sap_10_2_xml,
                       schema_name: "SAP-Schema-19.0.0",
                       scheme_ids: "1",
                       migrated: false,
                       overridden: false

      expect(country_use_case).to have_received(:execute).with(rrn: "0000-0000-0000-0000-0000", address_id: "UPRN-0000000001", postcode: "CF10 1EP").exactly(1).times
    end
  end
end
