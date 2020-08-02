describe ViewModel::Factory do
  it "constructs a CEPC object for CEPC-8.0.0 xml" do
    xml_file = File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
    xml_doc = Nokogiri.XML xml_file
    factory = described_class.new
    result = factory.create(xml_doc.to_xml, "CEPC-8.0.0")
    expect(result).to be_kind_of(ViewModel::Cepc::CepcWrapper)
  end

  it "can filter an xml document with multiple reports" do
    xml_file = File.read File.join Dir.pwd, "spec/fixtures/samples/cepc+rr.xml"
    xml_doc = Nokogiri.XML xml_file
    factory = described_class.new

    cepc_rr =
      factory.create(xml_doc.to_xml, "CEPC-8.0.0", "0000-0000-0000-0000-0001")
    expect(cepc_rr.to_hash[:assessment_id]).to eq("0000-0000-0000-0000-0001")
    expect(cepc_rr.to_hash[:type_of_assessment]).to eq("CEPC-RR")

    cepc =
      factory.create(xml_doc.to_xml, "CEPC-8.0.0", "0000-0000-0000-0000-0000")
    expect(cepc.to_hash[:assessment_id]).to eq("0000-0000-0000-0000-0000")
    expect(cepc.to_hash[:type_of_assessment]).to eq("CEPC")
  end
end
