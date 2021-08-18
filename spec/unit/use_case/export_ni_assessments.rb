describe UseCase::ExportNiAssessments do
  context "when exporting NI data call the use case" do
    subject do
      described_class.new(export_ni_gateway: ni_gateway, xml_gateway: xml_gateway)
    end

    let(:ni_gateway) do
      instance_double(Gateway::ExportNiGateway)
    end

    let(:xml_gateway) do
      instance_double(Gateway::AssessmentsXmlGateway)
    end

    before do
      domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
      allow(ni_gateway).to receive(:fetch_assessments).with(%w[RdSAP SAP]).and_return([{ "assessment_id" => "0000-0000-0000-0000-0000" }, { "assessment_id" => "8888-0000-0000-0000-0002" }, { "assessment_id" => "9999-0000-0000-0000-0000" }])
      allow(xml_gateway).to receive(:fetch).and_return({ xml: domestic_ni_sap_xml.to_xml, schema_type: "RdSAP-Schema-NI-20.0.0" })
    end

    it "loops over the lodged assessments and extract the correct certificates" do
      subject.execute(%w[RdSAP SAP])
      expect(xml_gateway).to have_received(:fetch).exactly(3).times
    end

    it "passes the xml to the view model" do
      expect { subject.execute(%w[RdSAP SAP]) }.not_to raise_error
    end

    it "returns a single hash in an array " do
      expect(subject.execute(%w[RdSAP SAP]).first).to match a_hash_including(assessment_id: "0000-0000-0000-0000-0000", address_line1: "1 Some Street")
    end
  end
end
