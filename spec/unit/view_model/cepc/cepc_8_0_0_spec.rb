describe ViewModel::Cepc::CepcWrapper do
  context "when constructed with a valid CEPC 8.0.0 document" do
    let(:cepc) do
      xml_file = File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
      xml_doc = Nokogiri.XML xml_file
      described_class.new(xml_doc.to_xml, "CEPC-8.0.0")
    end

    it "Returns the assessment ID" do
      expect(cepc.to_hash[:assessment_id]).to eq("0000-0000-0000-0000-0000")
    end
  end
end
