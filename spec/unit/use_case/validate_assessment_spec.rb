describe UseCase::ValidateAssessment do
  context "when given an existing RdSAP schema name" do
    let(:valid_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

    it "will return a boolean true when the XML is valid" do
      validate_assessment = described_class.new
      valid_xml_response =
        validate_assessment.execute(
          valid_xml,
          "api/schemas/xml/RdSAP-Schema-20.0.0/RdSAP/Templates/RdSAP-Report.xsd",
        )

      expect(valid_xml_response).to eq(true)
    end
  end
end
