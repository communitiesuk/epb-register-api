describe LodgementRules::NonDomestic, set_with_timecop: true do
  let(:docs_under_test) do
    [
      {
        xml_doc:
          Nokogiri.XML(Samples.xml("CEPC-8.0.0", "dec")).remove_namespaces!,
        schema_name: "CEPC-8.0.0",
      },
      {
        xml_doc:
          Nokogiri.XML(Samples.xml("CEPC-NI-8.0.0", "dec")).remove_namespaces!,
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
        ViewModel::Factory.new.create(xml_doc.to_xml, doc[:schema_name], false)
      adapter = wrapper.get_view_model
      errors = described_class.new.validate(adapter)
      expect(errors).to match_array(expected_errors)
    end
  end

  it "Returns an empty list for a valid file" do
    docs_under_test.each do |doc|
      xml = doc[:xml_doc]
      xml_doc = reset_dates_to_yesterday(xml)
      wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, doc[:schema_name])
      adapter = wrapper.get_view_model
      errors = described_class.new.validate(adapter)
      expect(errors).to eq([])
    end
  end

  context "MUST_RECORD_REASON_TYPE" do
    let(:error) do
      {
        "code": "MUST_RECORD_REASON_TYPE",
        "title": '"Reason-Type" must not be equal to 7',
      }.freeze
    end

    it "returns an error if the reason type is 7" do
      assert_errors("Reason-Type", "7", [error])
    end
  end

  context "MUST_RECORD_DEC_DISCLOSURE" do
    let(:error) do
      {
        "code": "MUST_RECORD_DEC_DISCLOSURE",
        "title": '"DEC-Related-Party-Disclosure" must not be equal to 8',
      }.freeze
    end

    it "returns an error if the dec related party disclosure is 8" do
      assert_errors("DEC-Related-Party-Disclosure", "8", [error])
    end
  end

  context "NOMINATED_DATE_TOO_LATE" do
    let(:error) do
      {
        "code": "NOMINATED_DATE_TOO_LATE",
        "title":
          '"Nominated-Date" must not be more than three months after "OR-Assessment-End-Date"',
      }.freeze
    end

    it "returns an error if the nominated date is more than three months after the or-assessment-end-date" do
      assert_errors("OR-Assessment-End-Date", "2019-09-30", [error])
    end
  end
end
