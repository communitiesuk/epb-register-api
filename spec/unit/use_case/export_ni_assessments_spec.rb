describe UseCase::ExportNiAssessments do
  context "when exporting NI data call the use case" do
    subject(:use_case) do
      described_class.new(export_ni_gateway: ni_gateway, xml_gateway: xml_gateway)
    end

    let(:ni_gateway) do
      instance_double(Gateway::ExportNiGateway)
    end

    let(:xml_gateway) do
      instance_double(Gateway::AssessmentsXmlGateway)
    end

    before(:all) do
      Timecop.freeze(2021, 2, 22, 0, 0, 0)
    end

    after(:all) do
      Timecop.return
    end

    before do
      domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
      allow(ni_gateway).to receive(:fetch_assessments).with(type_of_assessment: %w[RdSAP SAP], date_from: "1990-01-01", date_to: Time.now).and_return([
        { "assessment_id" => "0000-0000-0000-0000-0000", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => "UPRN-000000000001", "opt_out" => false, "cancelled" => false },
        { "assessment_id" => "8888-0000-0000-0000-0002", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => "UPRN-000000000000" },
        { "assessment_id" => "9999-0000-0000-0000-0000", "lodgement_date" => "2020-05-04", "lodgement_datetime" => "2021-02-22 00:00:00", "uprn" => nil },
      ])
      allow(xml_gateway).to receive(:fetch).and_return({ xml: domestic_ni_sap_xml.to_xml, schema_type: "RdSAP-Schema-NI-20.0.0" })
    end

    it "loops over the lodged assessments and extract the correct certificates" do
      use_case.execute(type_of_assessment: %w[RdSAP SAP])
      expect(xml_gateway).to have_received(:fetch).exactly(3).times
    end

    it "passes the xml to the view model" do
      expect { use_case.execute(type_of_assessment: %w[RdSAP SAP]) }.not_to raise_error
    end

    it "returns a single hash in an array that include the nodes from both to_hash_ni and the database " do
      expect(use_case.execute(type_of_assessment: %w[RdSAP SAP]).first).to match a_hash_including(
        assessment_id: "0000-0000-0000-0000-0000",
        address1: "1 Some Street",
        lodgement_date: "2020-05-04",
        lodgement_datetime: "2021-02-22 00:00:00",
        uprn: "UPRN-000000000001",
        opt_out: false,
        cancelled: false,
      )
    end
  end
end
