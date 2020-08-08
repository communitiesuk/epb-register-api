describe LodgementRules::DomesticCommon do
  let(:xml_file) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap.xml"
  end
  let(:xml_doc) do
    Nokogiri.XML(xml_file)
  end

  def get_xml_errors(key, value)
    xml_doc.at(key).children = value

    wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, "RdSAP-Schema-20.0.0", false, true)
    adapter = wrapper.get_view_model
    described_class.new.validate(adapter)
  end

  it "Returns an empty list for a valid file" do
    wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, "RdSAP-Schema-20.0.0", false, true)
    adapter = wrapper.get_view_model
    errors = described_class.new.validate(adapter)
    expect(errors).to eq([])
  end

  context "MUST_HAVE_HABITABLE_ROOMS" do
    let(:error) do
      {
          "code": "MUST_HAVE_HABITABLE_ROOMS",
          "title":
              '"Habitable-Room-Count" must be an integer and must be greater than or equal to 1',
      }.freeze
    end

    it "returns an error if the habitable room count is not an integer" do
      errors = get_xml_errors("Habitable-Room-Count", "6.2")
      expect(errors).to include(error)
    end

    it "returns an error if the habitable room count is zero" do
      errors = get_xml_errors("Habitable-Room-Count", "0")
      expect(errors).to include(error)
    end
  end
end
