require_relative "../../shared_context/shared_lodgement"

describe LodgementRules::ScottishSap do
  include_context "when lodging XML"

  let(:docs_under_test) { %w[SAP-Schema-S-19.0.0] }

  it "returns an empty list for a valid file" do
    rdsap_xml = Nokogiri.XML(Samples.xml("SAP-Schema-S-19.0.0"))
    rdsap_xml.at("Registration-Date").children = Date.today.to_s
    rdsap_xml.at("Inspection-Date").children = Date.today.to_s
    rdsap_xml.at("Completion-Date").children = Date.today.to_s
    country_lookup = Domain::CountryLookup.new(country_codes: [:S])
    wrapper =
      ViewModel::Factory.new.create(
        rdsap_xml.to_xml,
        "SAP-Schema-S-19.0.0",
        false,
      )
    adapter = wrapper.get_view_model

    errors = described_class.new.validate(adapter, country_lookup)
    expect(errors).to eq([])
  end

  context "when the inspection date is later than the completion date VAL100" do
    let(:error) do
      {
        "code": "SCOTLAND_INSPECTION_DATE_LATER_THAN_COMPLETION_DATE_VAL100",
        "title":
          "Date of dwelling survey (inspection date) cannot be any later than date of lodgement of data to the register",
      }.freeze
    end

    it "allows lodgement when the Completion-Date is after the Inspection-Date" do
      assert_errors(expected_errors: [],
                    values: { "Inspection-Date": Date.yesterday.to_s,
                              "Completion-Date": Date.today.to_s,
                              "Registration-Date": Date.today.to_s },
                    country_code: [:S])
    end

    it "allows lodgement when the Inspection-Date and the Completion-Date are equal" do
      assert_errors(expected_errors: [], values: { "Inspection-Date": Date.today.to_s,
                                                   "Completion-Date": Date.today.to_s,
                                                   "Registration-Date": Date.today.to_s },
                    country_code: [:S])
    end

    it "throws an error when the Inspection-Date is later than the Completion-Date (This will trigger a concurrent error VAL102)" do
      assert_errors(expected_errors: [error,
                                      {
                                        "code": "SCOTLAND_COMPLETION_DATE_IS_NOT_THE_SAME_AS_DATE_OF_LODGEMENT_VAL102",
                                        "title":
                                                "Date of certificate declared is not the same as date of lodgement to the register",
                                      }], values: { "Inspection-Date": Date.today.to_s,
                                                    "Completion-Date": Date.yesterday.to_s,
                                                    "Registration-Date": Date.today.to_s },
                    country_code: [:S])
    end
  end

  context "when the inspection date is more than three months earlier than completion date VAL101" do
    let(:error) do
      {
        "code": "SCOTLAND_INSPECTION_DATE_THREE_MONTHS_EARLIER_THAN_COMPLETION_DATE_VAL101",
        "title":
          "Date of dwelling survey (inspection date) should not be more than three months earlier than the completion date",
      }.freeze
    end

    it "allows lodgement when the Completion-Date less than three months after Inspection-Date" do
      assert_errors(expected_errors: [],
                    values: { "Inspection-Date": Date.yesterday.to_s,
                              "Completion-Date": Date.today.to_s },
                    country_code: [:S])
    end

    it "allows lodgement when the Completion-Date is exactly three months after Inspection-Date" do
      assert_errors(expected_errors: [], values: { "Inspection-Date": (Date.today << 3).to_s,
                                                   "Completion-Date": Date.today.to_s },
                    country_code: [:S])
    end

    it "throws an error when the Completion-Date is more than three months after Inspection-Date" do
      assert_errors(expected_errors: [error], values: {   "Inspection-Date": (Date.today << 4).to_s,
                                                          "Completion-Date": Date.today.to_s },
                    country_code: [:S])
    end
  end

  context "when the completion date is not the same as the date of lodgement VAL102" do
    let(:error) do
      {
        "code": "SCOTLAND_COMPLETION_DATE_IS_NOT_THE_SAME_AS_DATE_OF_LODGEMENT_VAL102",
        "title":
          "Date of certificate declared is not the same as date of lodgement to the register",
      }.freeze
    end

    it "allows lodgement when the Completion-Date is the same as date of lodgement" do
      assert_errors(expected_errors: [],
                    values: { "Completion-Date": Date.today.to_s,
                              "Inspection-Date": Date.yesterday.to_s },
                    country_code: [:S])
    end

    it "throws an error when the Completion-Date is not today" do
      assert_errors(expected_errors: [error], values: { "Completion-Date": Date.yesterday.to_s, "Inspection-Date": Date.yesterday.to_s },
                    country_code: [:S])
    end
  end

  context "when the floor area is greater than 450 VAL103" do
    let(:error) do
      {
        "code": "SCOTLAND_TOTAL_FLOOR_AREA_GREATER_THAN_450_VAL103",
        "title":
          "Very large total floor area (>450) reported",
      }.freeze
    end

    it "allows lodgement when the total floor area is greater than 30" do
      assert_errors(expected_errors: [],
                    values: { "Total-Floor-Area": "35",
                              "Completion-Date": Date.today.to_s,
                              "Inspection-Date": Date.yesterday.to_s },
                    country_code: [:S])
    end

    it "raises an error when the total floor area is less than 30" do
      assert_errors(expected_errors: [error],
                    values: { "Total-Floor-Area": "456",
                              "Completion-Date": Date.today.to_s,
                              "Inspection-Date": Date.yesterday.to_s },
                    country_code: [:S])
    end
  end

  context "when both main heating index number and main heating code are missing VAL104" do
    let(:error) do
      {
        "code": "SCOTLAND_BOTH_MAIN_HEATING_INDEX_NUMBER_AND_MAIN_HEATING_CODE_MISSING_VAL104",
        "title":
          "Neither Main-Heating-Index-Number nor Main-Heating-Code recorded for this dwelling",
      }.freeze
    end

    it "allows lodgement when both are present" do
      assert_errors(expected_errors: [],
                    values: {
                      "Main-Heating Main-Heating-Index-Number": "35",
                      "Main-Heating Main-Heating-Code": "009899",
                      "Completion-Date": Date.today.to_s,
                      "Inspection-Date": Date.yesterday.to_s,
                    },
                    country_code: [:S])
    end

    it "allows lodgement when main heating code is present" do
      assert_errors(expected_errors: [],
                    values: {
                      "Main-Heating Main-Heating-Index-Number": :delete,
                      "Main-Heating Main-Heating-Code": "009899",
                      "Completion-Date": Date.today.to_s,
                      "Inspection-Date": Date.yesterday.to_s,
                    },
                    country_code: [:S])
    end

    it "allows lodgement when main heating index number is present" do
      assert_errors(expected_errors: [],
                    values: {
                      "Main-Heating Main-Heating-Index-Number": "35",
                      "Main-Heating Main-Heating-Code": :delete,
                      "Completion-Date": Date.today.to_s,
                      "Inspection-Date": Date.yesterday.to_s,
                    },
                    country_code: [:S])
    end

    it "raises an error when both are absent" do
      assert_errors(expected_errors: [error],
                    values: {
                      "Main-Heating Main-Heating-Index-Number": :delete,
                      "Main-Heating Main-Heating-Code": :delete,
                      "Completion-Date": Date.today.to_s,
                      "Inspection-Date": Date.yesterday.to_s,
                    },
                    country_code: [:S])
    end
  end

  context "when the construction year is missing from a building part VAL106" do
    let(:error) do
      {
        "code": "SCOTLAND_CONSTRUCTION_YEAR_MISSING_FROM_BUILDING_PART_VAL106",
        "title":
          "No construction year defined for dwelling part",
      }.freeze
    end

    it "allows lodgement when construction year is present" do
      assert_errors(expected_errors: [],
                    values: { "Construction-Year": "1935",
                              "Completion-Date": Date.today.to_s,
                              "Inspection-Date": Date.yesterday.to_s },
                    country_code: [:S])
    end

    it "raises an error when construction year is not present" do
      assert_errors(expected_errors: [error],
                    values: { "Construction-Year": :delete,
                              "Completion-Date": Date.today.to_s,
                              "Inspection-Date": Date.yesterday.to_s },
                    country_code: [:S])
    end
  end

  context "when the address is not in Scotland" do
    let(:error) do
      {
        "code": "INVALID_COUNTRY",
        "title": "Property address must be in Scotland",
      }.freeze
    end

    it "returns an error if the address is in England" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "SW1A 2AA",
                                                        "Inspection-Date": Date.yesterday.to_s,
                                                        "Completion-Date": Date.today.to_s,
                                                        "Registration-Date": Date.today.to_s }, country_code: [:E])
    end

    it "returns an error if the address is NI" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "BT3 9EP",
                                                        "Inspection-Date": Date.yesterday.to_s,
                                                        "Completion-Date": Date.today.to_s,
                                                        "Registration-Date": Date.today.to_s }, country_code: [:N])
    end

    it "returns an error if the address is Wales" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "CF99 1NA",
                                                        "Inspection-Date": Date.yesterday.to_s,
                                                        "Completion-Date": Date.today.to_s,
                                                        "Registration-Date": Date.today.to_s }, country_code: [:W])
    end

    it "returns an error if the address is JE" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "JE3 6HW",
                                                        "Inspection-Date": Date.yesterday.to_s,
                                                        "Completion-Date": Date.today.to_s,
                                                        "Registration-Date": Date.today.to_s }, country_code: [:L])
    end

    it "returns an error if the address is GY" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "GY7 9QS",
                                                        "Inspection-Date": Date.yesterday.to_s,
                                                        "Completion-Date": Date.today.to_s,
                                                        "Registration-Date": Date.today.to_s }, country_code: [:L])
    end

    it "returns an error if the address is IM" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "IM7 3BZ",
                                                        "Inspection-Date": Date.yesterday.to_s,
                                                        "Completion-Date": Date.today.to_s,
                                                        "Registration-Date": Date.today.to_s }, country_code: [:L])
    end

    it "returns an error if the country code is in England" do
      assert_errors(expected_errors: [error], values: { "Country-Code": "ENG",
                                                        "Inspection-Date": Date.yesterday.to_s,
                                                        "Completion-Date": Date.today.to_s,
                                                        "Registration-Date": Date.today.to_s }, country_code: [:E])
    end

    it "returns an error if the country code is in Wales" do
      assert_errors(expected_errors: [error], values: { "Country-Code": "WLS",
                                                        "Inspection-Date": Date.yesterday.to_s,
                                                        "Completion-Date": Date.today.to_s,
                                                        "Registration-Date": Date.today.to_s }, country_code: [:W])
    end

    it "returns an error if the country code is in England or Wales" do
      assert_errors(expected_errors: [error], values: { "Country-Code": "EAW",
                                                        "Inspection-Date": Date.yesterday.to_s,
                                                        "Completion-Date": Date.today.to_s,
                                                        "Registration-Date": Date.today.to_s }, country_code: [:W])
    end

    it "returns no error if the country code is in Scotland" do
      assert_errors(expected_errors: [], values: { "Country-Code": "SCT",
                                                   "Inspection-Date": Date.yesterday.to_s,
                                                   "Completion-Date": Date.today.to_s,
                                                   "Registration-Date": Date.today.to_s }, country_code: [:S])
    end

    it "returns no error if the address is in Scotland" do
      assert_errors(expected_errors: [], values: { "Address/Postcode": "EH1 2NG",
                                                   "Inspection-Date": Date.yesterday.to_s,
                                                   "Completion-Date": Date.today.to_s,
                                                   "Registration-Date": Date.today.to_s }, country_code: [:S])
    end

    it "returns no error if the postcode crosses the English/Scottish border" do
      assert_errors(expected_errors: [], values: { "Address/Postcode": "TD15 1UZ",
                                                   "Inspection-Date": Date.yesterday.to_s,
                                                   "Completion-Date": Date.today.to_s,
                                                   "Registration-Date": Date.today.to_s }, country_code: %i[E S])
    end
  end
end
