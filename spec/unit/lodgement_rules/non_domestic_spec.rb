describe LodgementRules::NonDomestic do
  let(:xml_file) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
  end
  let(:xml_doc) { Nokogiri.XML(xml_file) }

  it "Returns an empty list for a valid file" do
    wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, "CEPC-8.0.0")
    adapter = wrapper.get_view_model
    errors = described_class.new.validate(adapter)
    expect(errors).to eq([])
  end

  context "INSPECTION_REGISTRATION_ISSUE_DATE" do
    it "returns an error if the inspection date is in the future" do
      rrn = xml_doc.at("//CEPC:Inspection-Date")
      rrn.children = Date.tomorrow.to_s

      wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, "CEPC-8.0.0")
      adapter = wrapper.get_view_model
      errors = described_class.new.validate(adapter)
      expect(errors).to eq(
        [
          {
            "code": "INSPECTION_REGISTRATION_ISSUE_DATE",
            "message":
              '"Inspection-Date", "Registration-Date" and "Issue-Date" must not be in the future and must not be more than 4 years ago',
          },
        ],
      )
    end
  end
end
