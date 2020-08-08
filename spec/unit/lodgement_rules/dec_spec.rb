describe LodgementRules::NonDomestic do

  let(:docs_under_test) do
    [
        {
            xml_doc:
                Nokogiri.XML(
                    File.read(File.join(Dir.pwd, "spec/fixtures/samples/dec.xml")),
                    ).remove_namespaces!,
            schema_name: "CEPC-8.0.0",
        },
        {
            xml_doc:
                Nokogiri.XML(
                    File.read(File.join(Dir.pwd, "spec/fixtures/samples/dec-ni.xml")),
                    ).remove_namespaces!,
            schema_name: "CEPC-NI-8.0.0",
        },
    ]
  end

  def reset_dates_to_yesterday(xml_doc)
    yesterday = Date.yesterday.to_s
    xml_doc
  end

  def assert_errors(key, value, expected_errors)
    docs_under_test.each do |doc|
      xml_doc = doc[:xml_doc]
      xml_doc.at(key).children = value

      wrapper =
          ViewModel::Factory.new.create(
              xml_doc.to_xml,
              doc[:schema_name],
              false,
              true,
              )
      adapter = wrapper.get_view_model
      errors = described_class.new.validate(adapter)
      expect(errors).to match_array(expected_errors)
    end
  end

  it "Returns an empty list for a valid file" do
    docs_under_test.each{ | doc |
      xml = doc[:xml_doc]
      xml_doc = reset_dates_to_yesterday(xml)
      wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, doc[:schema_name])
      adapter = wrapper.get_view_model
      errors = described_class.new.validate(adapter)
      expect(errors).to eq([])
    }
  end
end
