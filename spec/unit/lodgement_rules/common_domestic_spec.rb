describe LodgementRules::DomesticCommon do
  let(:xml_file) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/sap.xml"
  end
  let(:xml_doc) do
    Nokogiri.XML(xml_file)
  end

  def get_xml_errors(key, value)
    xml_doc.at(key).children = value

    wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, "SAP-Schema-18.0.0", false, true)
    adapter = wrapper.get_view_model
    described_class.new.validate(adapter)
  end

  it "Returns an empty list for a valid file" do
    wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, "SAP-Schema-18.0.0", false, true)
    adapter = wrapper.get_view_model
    errors = described_class.new.validate(adapter)
    expect(errors).to eq([])
  end
end
