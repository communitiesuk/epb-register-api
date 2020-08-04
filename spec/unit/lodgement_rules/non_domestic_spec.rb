describe LodgementRules::NonDomestic do

  context "Validating a non domestic xml file" do
    let(:xml_file) {File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"}
    let(:xml_doc) {Nokogiri.XML(xml_file)}
    it "Returns an empty list for a valid file" do
      xml_adapter = ViewModel::Cepc::Cepc800.new(xml_doc.to_xml)
      errors = described_class.new.validate(xml_adapter)
      expect(errors).to eq([])
    end
  end
end
