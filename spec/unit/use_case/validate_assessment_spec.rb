describe UseCase::ValidateAssessment do
  context 'given an existing RdSAP schema name' do
    let(:valid_xml) do
      File.read File.join Dir.pwd, 'api/schemas/xml/examples/RdSAP-19.01.xml'
    end

    it 'will return a boolean true when the XML is valid' do
      validate_assessment = described_class.new
      valid_xml_response =
        validate_assessment.execute(
          valid_xml,
          'application/xml+RdSAP-Schema-19.0'
        )

      expect(valid_xml_response).to eq(true)
    end
  end
end
