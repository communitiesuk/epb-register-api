require_relative "../../shared_context/shared_lodgement"

describe LodgementRules::ScottishRdsap, :set_with_timecop do
  include_context "when lodging XML"
  let(:docs_under_test) { %w[RdSAP-Schema-S-19.0] }

  it "returns an empty list for a valid file" do
    country_lookup = Domain::CountryLookup.new(country_codes: [:S])

    docs_under_test.each do |doc|
      wrapper =
        ViewModel::Factory.new.create(
          Nokogiri.XML(Samples.xml(doc)).to_xml,
          doc,
          false,
        )
      adapter = wrapper.get_view_model

      errors = described_class.new.validate(adapter, country_lookup)
      expect(errors).to eq([])
    end
  end

  # context "when the inspection date is later than the completion date" do
  #   let(:error) do
  #     {
  #       "code": "INSPECTION_DATE_LATER_THAN_COMPLETION_DATE VAL009",
  #       "title":
  #         "Date of dwelling survey (inspection date) cannot be any later than date of lodgement of data to the register",
  #     }.freeze
  #   end
  #
  #   it "allows lodgement when the Completion-Date is after the Inspection-Date" do
  #     assert_errors(expected_errors: [],
  #                   values: { "Inspection-Date": Date.yesterday.to_s,
  #                             "Completion-Date": Date.today.to_s,
  #                             "Registration-Date": Date.today.to_s },
  #                   country_code: [:S])
  #   end
  #
  #   it "allows lodgement when the Inspection-Date and the Completion-Date are equal" do
  #     assert_errors(expected_errors: [], values: { "Inspection-Date": Date.today.to_s,
  #                                                  "Completion-Date": Date.today.to_s,
  #                                                  "Registration-Date": Date.today.to_s },
  #                   country_code: [:S])
  #   end
  #
  #   it "throws an error when the Inspection-Date is later than the Completion-Date" do
  #     assert_errors(expected_errors: [error], values: {   "Inspection-Date": Date.today.to_s,
  #                                                         "Completion-Date": Date.yesterday.to_s,
  #                                                         "Registration-Date": Date.today.to_s },
  #                   country_code: [:S])
  #   end
  # end

  context "when the address is not in Scotland" do
    let(:error) do
      {
        "code": "INVALID_COUNTRY",
        "title": "Property address must be in Scotland",
      }.freeze
    end

    it "returns an error if the address is in England" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "SW1A 2AA" }, country_code: [:E])
    end

    it "returns an error if the address is NI" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "BT3 9EP" }, country_code: [:N])
    end

    it "returns an error if the address is Wales" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "CF99 1NA" }, country_code: [:W])
    end

    it "returns an error if the address is JE" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "JE3 6HW" }, country_code: [:L])
    end

    it "returns an error if the address is GY" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "GY7 9QS" }, country_code: [:L])
    end

    it "returns an error if the address is IM" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "IM7 3BZ" }, country_code: [:L])
    end

    it "returns an error if the country code is in England" do
      assert_errors(expected_errors: [error], values: { "Country-Code": "ENG" }, country_code: [:E])
    end

    it "returns an error if the country code is in Wales" do
      assert_errors(expected_errors: [error], values: { "Country-Code": "WLS" }, country_code: [:W])
    end

    it "returns an error if the country code is in England or Wales" do
      assert_errors(expected_errors: [error], values: { "Country-Code": "EAW" }, country_code: [:W])
    end

    it "returns no error if the country code is in Scotland" do
      assert_errors(expected_errors: [], values: { "Country-Code": "SCT" }, country_code: [:S])
    end

    it "returns no error if the address is in Scotland" do
      assert_errors(expected_errors: [], values: { "Address/Postcode": "EH1 2NG" }, country_code: [:S])
    end

    it "returns no error if the postcode crosses the English/Scottish border" do
      assert_errors(expected_errors: [], values: { "Address/Postcode": "TD15 1UZ" }, country_code: %i[E S])
    end
  end
end
