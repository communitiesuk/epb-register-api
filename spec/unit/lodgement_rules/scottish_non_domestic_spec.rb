shared_context "when testing non-domestic lodgements" do
  def assert_errors(xml_updates, expected_errors, include_errors: false, country_code: nil)
    docs_under_test.each do |doc|
      xml_doc = doc[:xml_doc]
      xml_updates.each do |key, value|
        xml_doc.at(key).children = value
      end
      wrapper =
        ViewModel::Factory.new.create(xml_doc.to_xml, doc[:schema_name], false)
      adapter = wrapper.get_view_model
      lookup_country_code = if country_code.nil?
                              [:S]
                            else
                              country_code
                            end
      country_lookup = Domain::CountryLookup.new(country_codes: lookup_country_code)
      errors = described_class.new.validate(adapter, country_lookup)
      include_errors ? expect(errors).to(include(*expected_errors)) : expect(errors).to(match_array(expected_errors))
    end
  end

  def do_expect(doc)
    xml_doc = doc[:xml_doc]
    wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, doc[:schema_name])
    adapter = wrapper.get_view_model
    country_code = [:S]
    described_class.new.validate(adapter, Domain::CountryLookup.new(country_codes: country_code))
  end
end

describe LodgementRules::ScottishNonDomestic, :set_with_timecop do
  include_context "when testing non-domestic lodgements"

  context "when CEPC are lodged for" do
    let!(:docs_under_test) do
      [
        {
          xml_doc:
            Nokogiri.XML(Samples.xml("CEPC-S-7.1", "cepc")).remove_namespaces!,
          schema_name: "CEPC-S-7.1",
        },
      ]
    end

    it "Returns an empty list for a valid file" do
      docs_under_test.each do |doc|
        expect(do_expect(doc)).to eq([])
      end
    end

    context "when the inspection date is later than the completion date VAL200" do
      let(:error) do
        {
          "code": "INSPECTION_DATE_LATER_THAN_COMPLETION_DATE_VAL200",
          "title":
            "Date of building assessment (inspection date) cannot be any later than date of lodgement of data to the register",
        }.freeze
      end

      it "returns an error if the inspection date is in the future" do
        assert_errors([["Inspection-Date", Date.today.to_s], ["Completion-Date", Date.yesterday.to_s]], [error], include_errors: true)
      end
    end

    context "when the inspection date is more than three months earlier than completion date VAL201" do
      let(:error) do
        {
          "code": "INSPECTION_DATE_THREE_MONTHS_EARLIER_THAN_COMPLETION_DATE_VAL201",
          "title":
            "Building assessment not completed recently; data used for lodgement is more than three months old",
        }.freeze
      end

      it "returns an error if the inspection date is more than four years ago" do
        three_months_and_a_day = (Date.today << 3) - 1
        assert_errors([["Inspection-Date", three_months_and_a_day.to_s], ["Completion-Date", Date.today.to_s]], [error])
      end
    end
  end
end
