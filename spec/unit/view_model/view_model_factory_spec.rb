describe ViewModel::Factory do
  it "constructs a CEPC object for CEPC-8.0.0 xml" do
    xml_file = File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
    xml_doc = Nokogiri.XML xml_file
    factory = described_class.new
    result = factory.create(xml_doc.to_xml, "CEPC-8.0.0")
    expect(result).to be_kind_of(ViewModel::Cepc::CepcWrapper)
  end
end
