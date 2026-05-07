require_relative "../../shared_context/shared_lodgement"

def assert_rdsap_errors(expected_errors:, values: nil, new_nodes: [], country_code: [:E], schema: "RdSAP-Schema-S-19.0", file_name: "epc")
  country_lookup = Domain::CountryLookup.new(country_codes: country_code)

  xml_doc = Nokogiri.XML(Samples.xml(schema, file_name))

  values.each do |k, v|
    if v == :delete
      xml_doc.at(k).remove
    else
      xml_doc.at(k).children = v
    end
  end

  new_nodes.each do |node|
    xml_doc.at(node[:selector]).add_next_sibling(node[:xml])
  end

  wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, schema, false)
  adapter = wrapper.get_view_model
  errors = described_class.new.validate(adapter, country_lookup)
  expect(errors).to match_array(expected_errors)
end

describe LodgementRules::ScottishRdsap do
  include_context "when lodging XML"

  it "returns an empty list for a valid file" do
    rdsap_xml = Nokogiri.XML(Samples.xml("RdSAP-Schema-S-19.0"))
    rdsap_xml.at("Registration-Date").children = Date.today.to_s
    rdsap_xml.at("Inspection-Date").children = Date.today.to_s
    rdsap_xml.at("Completion-Date").children = Date.today.to_s
    country_lookup = Domain::CountryLookup.new(country_codes: [:S])
    wrapper =
      ViewModel::Factory.new.create(
        rdsap_xml.to_xml,
        "RdSAP-Schema-S-19.0",
        false,
      )
    adapter = wrapper.get_view_model

    errors = described_class.new.validate(adapter, country_lookup)
    expect(errors).to eq([])
  end

  context "when the inspection date is later than the completion date VAL009" do
    let(:error) do
      {
        "code": "SCOTLAND_INSPECTION_DATE_LATER_THAN_COMPLETION_DATE_VAL009",
        "title":
          "Date of dwelling survey (inspection date) cannot be any later than date of lodgement of data to the register",
      }.freeze
    end

    it "allows lodgement when the Completion-Date is after the Inspection-Date" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Inspection-Date": Date.yesterday.to_s,
                                    "Completion-Date": Date.today.to_s,
                                    "Registration-Date": Date.today.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when the Inspection-Date and the Completion-Date are equal" do
      assert_rdsap_errors(expected_errors: [], values: { "Inspection-Date": Date.today.to_s,
                                                         "Completion-Date": Date.today.to_s,
                                                         "Registration-Date": Date.today.to_s },
                          country_code: [:S])
    end

    it "throws an error when the Inspection-Date is later than the Completion-Date (This will trigger a concurrent error VAL011)" do
      assert_rdsap_errors(expected_errors: [error,
                                            {
                                              "code": "SCOTLAND_COMPLETION_DATE_IS_NOT_THE_SAME_AS_DATE_OF_LODGEMENT_VAL011",
                                              "title":
                                                      "Date of certificate declared is not the same as date of lodgement to the register",
                                            }], values: { "Inspection-Date": Date.today.to_s,
                                                          "Completion-Date": Date.yesterday.to_s,
                                                          "Registration-Date": Date.today.to_s },
                          country_code: [:S])
    end
  end

  context "when the inspection date is more than three months earlier than completion date VAL010" do
    let(:error) do
      {
        "code": "SCOTLAND_INSPECTION_DATE_THREE_MONTHS_EARLIER_THAN_COMPLETION_DATE_VAL010",
        "title":
          "Date of dwelling survey (inspection date) should not be more than three months earlier than the completion date",
      }.freeze
    end

    it "allows lodgement when the Completion-Date less than three months after Inspection-Date" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Inspection-Date": Date.yesterday.to_s,
                                    "Completion-Date": Date.today.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when the Completion-Date is exactly three months after Inspection-Date" do
      assert_rdsap_errors(expected_errors: [], values: { "Inspection-Date": (Date.today << 3).to_s,
                                                         "Completion-Date": Date.today.to_s },
                          country_code: [:S])
    end

    it "throws an error when the Completion-Date is more than three months after Inspection-Date" do
      assert_rdsap_errors(expected_errors: [error], values: { "Inspection-Date": (Date.today << 4).to_s,
                                                              "Completion-Date": Date.today.to_s },
                          country_code: [:S])
    end
  end

  context "when the completion date is not the same as the date of lodgement VAL011" do
    let(:error) do
      {
        "code": "SCOTLAND_COMPLETION_DATE_IS_NOT_THE_SAME_AS_DATE_OF_LODGEMENT_VAL011",
        "title":
          "Date of certificate declared is not the same as date of lodgement to the register",
      }.freeze
    end

    it "allows lodgement when the Completion-Date is the same as date of lodgement" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "throws an error when the Completion-Date is not today" do
      assert_rdsap_errors(expected_errors: [error], values: { "Completion-Date": Date.yesterday.to_s, "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when the built form is detached party walls are not applicable VAL001" do
    let(:error) do
      {
        "code": "SCOTLAND_PARTY_WALLS_ARE_NOT_APPLICABLE_FOR_DETACHED_PROPERTIES_VAL001",
        "title":
          "When the build form for a property is detached, party walls must be recorded as not applicable",
      }.freeze
    end

    it "allows lodgement when there are no party walls for a detached property" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Built-Form": "1",
                                    "Party-Wall-Construction": "NA",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when there is a party wall for a detached property" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Built-Form": "1",
                                    "Party-Wall-Construction": "1",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when the built form is detached party walls are not applicable VAL003" do
    let(:error) do
      {
        "code": "SCOTLAND_PARTY_WALLS_ARE_NOT_DEFINED_USING_CURRENT_SURVEY_INFORMATION_VAL003",
        "title":
          "Party walls must be defined using current survey information",
      }.freeze
    end

    it "allows lodgement when the description for party walls is not NI" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Party-Wall-Construction": "5",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when the description for party walls is NI" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Party-Wall-Construction": "NI",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when the floor area is less than 30 VAL012" do
    let(:error) do
      {
        "code": "SCOTLAND_TOTAL_FLOOR_AREA_LESS_THAN_30_VAL012",
        "title":
          "Very small total floor area (<30) reported",
      }.freeze
    end

    it "allows lodgement when the total floor area is greater than 30" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Total-Floor-Area": "35",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when the total floor area is less than 30" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Total-Floor-Area": "20",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when the floor area is greater than 299 VAL013" do
    let(:error) do
      {
        "code": "SCOTLAND_TOTAL_FLOOR_AREA_GREATER_THAN_299_VAL013",
        "title":
          "Very large total floor area (>299) reported",
      }.freeze
    end

    it "allows lodgement when the total floor area is greater than 30" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Total-Floor-Area": "35",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when the total floor area is less than 30" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Total-Floor-Area": "299.5",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when the energy consumption current is less than 50 VAL015" do
    let(:error) do
      {
        "code": "SCOTLAND_PRIMARY_ENERGY_VALUE_LESS_THAN_50_VAL015",
        "title":
          "Very low primary energy value (<50) reported",
      }.freeze
    end

    it "allows lodgement when the primary energy value is greater than 50" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Energy-Consumption-Current": "56",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when the primary energy value is less than 50" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Energy-Consumption-Current": "45",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when the energy consumption current is greater than 849 VAL016" do
    let(:error) do
      {
        "code": "SCOTLAND_PRIMARY_ENERGY_VALUE_GREATER_THAN_849_VAL016",
        "title":
          "Very high primary energy value (>849) reported",
      }.freeze
    end

    it "allows lodgement when the primary energy value is less than 849" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Energy-Consumption-Current": "840",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when the primary energy value is greater than 849" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Energy-Consumption-Current": "865",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when any wall thickness is greater than 801 VAL004" do
    let(:error) do
      {
        "code": "SCOTLAND_WALL_THICKNESS_GREATER_THAN_801_VAL004",
        "title":
          "Unusually think walls (>801) reported for dwelling part",
      }.freeze
    end

    it "allows lodgement when all wall thicknesses are less than 801" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": "679",
                                    "SAP-Alternative-Wall Wall-Thickness": "673",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when wall thicknesses are missing" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "SAP-Building-Part Wall-Thickness": :delete,
                                    "SAP-Alternative-Wall": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when wall one thickness is missing" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "SAP-Building-Part Wall-Thickness": "679",
                                    "SAP-Alternative-Wall": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when all wall thicknesses are greater than 849" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Thickness": "865",
                                    "SAP-Alternative-Wall Wall-Thickness": "893",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when any wall thickness is greater than 849" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Thickness": "865",
                                    "SAP-Alternative-Wall Wall-Thickness": "483",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when any wall thickness less than 140 and wall construction is park home or system built VAL006" do
    let(:error) do
      {
        "code": "SCOTLAND_WALL_THICKNESS_LESS_THAN_140_NOT_PARK_HOME_OR_SYSTEM_BUILT_VAL006",
        "title":
          "Very low wall thickness (<140) reported and construction not park home or system built",
      }.freeze
    end

    it "allows lodgement when all wall thicknesses are missing" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": :delete,
                                    "Wall-Construction": "2",
                                    "SAP-Alternative-Wall": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when wall thicknesses is missing and alternative wall is greater than 140" do
      assert_rdsap_errors(expected_errors: [],
                          values: {
                            "SAP-Alternative-Wall Wall-Thickness": "145",
                            "Wall-Thickness": :delete,
                            "Wall-Construction": "3",
                            "SAP-Alternative-Wall Wall-Construction": "2",
                            "Completion-Date": Date.today.to_s,
                            "Inspection-Date": Date.yesterday.to_s,
                          },
                          country_code: [:S])
    end

    it "allows lodgement when alternative wall is missing and wall thickness is greater than 140" do
      assert_rdsap_errors(expected_errors: [],
                          values: {
                            "Wall-Thickness": "145",
                            "Wall-Construction": "3",
                            "SAP-Alternative-Wall": :delete,
                            "Completion-Date": Date.today.to_s,
                            "Inspection-Date": Date.yesterday.to_s,
                          },
                          country_code: [:S])
    end

    it "allows lodgement when alternative wall thicknesses is missing and wall is less than 140 but it is a built system" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": "120",
                                    "SAP-Alternative-Wall Wall-Thickness": :delete,
                                    "Wall-Construction": "8",
                                    "SAP-Alternative-Wall Wall-Construction": "8",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when wall thicknesses is missing and alternative wall is less than 140 but it is a built system" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": :delete,
                                    "SAP-Alternative-Wall Wall-Thickness": "120",
                                    "Wall-Construction": "3",
                                    "SAP-Alternative-Wall Wall-Construction": "8",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when all wall thicknesses are less than 140 and all wall constructions are park home or system built" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": "120",
                                    "SAP-Alternative-Wall Wall-Thickness": "120",
                                    "Wall-Construction": "10",
                                    "SAP-Alternative-Wall Wall-Construction": "10",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when one wall thicknesses are less than 140 and one wall constructions are park home or system built" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": "120",
                                    "SAP-Alternative-Wall Wall-Thickness": "180",
                                    "Wall-Construction": "10",
                                    "SAP-Alternative-Wall Wall-Construction": "3",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when alternative wall thickness is less than 140 and corresponding construction is not park home or system built" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Thickness": "483",
                                    "SAP-Alternative-Wall Wall-Thickness": "120",
                                    "Wall-Construction": "2",
                                    "SAP-Alternative-Wall Wall-Construction": "3",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when any wall thickness is less than 140 and corresponding construction is not park home or system built" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Thickness": "120",
                                    "SAP-Alternative-Wall Wall-Thickness": "463",
                                    "Wall-Construction": "2",
                                    "SAP-Alternative-Wall Wall-Construction": "3",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when all wall thicknesses are less than 140 and corresponding construction is not park home or system built" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Thickness": "120",
                                    "SAP-Alternative-Wall Wall-Thickness": "117",
                                    "Wall-Construction": "2",
                                    "SAP-Alternative-Wall Wall-Construction": "3",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when any wall thickness less than 230 and wall construction is cavity VAL007" do
    let(:error) do
      {
        "code": "SCOTLAND_WALL_THICKNESS_LESS_THAN_230_WITH_CAVITY_VAL007",
        "title":
          "Wall thickness of less than 230mm reported for cavity wall construction",
      }.freeze
    end

    it "allows lodgement when all wall thicknesses are missing but wall construction is cavity" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": :delete,
                                    "Wall-Construction": "4",
                                    "SAP-Alternative-Wall": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when wall thicknesses is missing and alternative wall is greater than 230" do
      assert_rdsap_errors(expected_errors: [],
                          values: {
                            "SAP-Alternative-Wall Wall-Thickness": "245",
                            "Wall-Thickness": :delete,
                            "Wall-Construction": "4",
                            "SAP-Alternative-Wall Wall-Construction": "4",
                            "Completion-Date": Date.today.to_s,
                            "Inspection-Date": Date.yesterday.to_s,
                          },
                          country_code: [:S])
    end

    it "allows lodgement when alternative wall is missing and wall thickness is greater than 230" do
      assert_rdsap_errors(expected_errors: [],
                          values: {
                            "Wall-Thickness": "245",
                            "Wall-Construction": "4",
                            "SAP-Alternative-Wall": :delete,
                            "Completion-Date": Date.today.to_s,
                            "Inspection-Date": Date.yesterday.to_s,
                          },
                          country_code: [:S])
    end

    it "allows lodgement when alternative wall thicknesses is missing and wall is less than 230 but it is not cavity" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": "120",
                                    "SAP-Alternative-Wall Wall-Thickness": :delete,
                                    "Wall-Construction": "8",
                                    "SAP-Alternative-Wall Wall-Construction": "8",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when wall thicknesses is missing and alternative wall is less than 230 but it it is not cavity" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": :delete,
                                    "SAP-Alternative-Wall Wall-Thickness": "120",
                                    "Wall-Construction": "3",
                                    "SAP-Alternative-Wall Wall-Construction": "8",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when all wall thicknesses are less than 230 and all wall constructions are not cavity" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": "120",
                                    "SAP-Alternative-Wall Wall-Thickness": "120",
                                    "Wall-Construction": "10",
                                    "SAP-Alternative-Wall Wall-Construction": "10",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when alternative wall thickness is less than 230 and corresponding construction is cavity" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Thickness": "483",
                                    "SAP-Alternative-Wall Wall-Thickness": "220",
                                    "Wall-Construction": "2",
                                    "SAP-Alternative-Wall Wall-Construction": "4",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when any wall thickness is less than 230 and corresponding construction is cavity" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Thickness": "220",
                                    "SAP-Alternative-Wall Wall-Thickness": "463",
                                    "Wall-Construction": "4",
                                    "SAP-Alternative-Wall Wall-Construction": "3",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when all wall thicknesses are less than 230 and corresponding construction is cavity" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Thickness": "220",
                                    "SAP-Alternative-Wall Wall-Thickness": "217",
                                    "Wall-Construction": "4",
                                    "SAP-Alternative-Wall Wall-Construction": "4",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when any wall thickness measured is N then a wall thickness cannot be given VAL008" do
    let(:error) do
      {
        "code": "SCOTLAND_WALL_THICKNESS_MEASURED_IS_N_BUT_WALL_THICKNESS_PRESENT_VAL008",
        "title":
          "Wall thickness recorded as not measured but wall thickness value provided by assessor",
      }.freeze
    end

    it "allows lodgement when all wall thicknesses are measured and wall thicknesses are present" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": "230",
                                    "Wall-Construction": "4",
                                    "Wall-Thickness-Measured": "Y",
                                    "SAP-Alternative-Wall Wall-Thickness": "245",
                                    "SAP-Alternative-Wall Wall-Construction": "4",
                                    "SAP-Alternative-Wall Wall-Thickness-Measured": "y",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when wall thickness is measured and wall thicknesses are present and there is no alternative wall" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": "230",
                                    "Wall-Construction": "4",
                                    "Wall-Thickness-Measured": "Y",
                                    "SAP-Alternative-Wall": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when alternative wall thicknesses are measured and wall thicknesses are present and there is no wall" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Thickness": :delete,
                                    "Wall-Construction": "4",
                                    "Wall-Thickness-Measured": "Y",
                                    "SAP-Alternative-Wall Wall-Thickness": "245",
                                    "SAP-Alternative-Wall Wall-Construction": "4",
                                    "SAP-Alternative-Wall Wall-Thickness-Measured": "y",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when wall thicknesses measure is N and wall thickness is present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Thickness": "245",
                                    "Wall-Construction": "4",
                                    "Wall-Thickness-Measured": "N",
                                    "SAP-Alternative-Wall Wall-Thickness": "245",
                                    "SAP-Alternative-Wall Wall-Construction": "4",
                                    "SAP-Alternative-Wall Wall-Thickness-Measured": "Y",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when alternative wall thickness measure is N and alternative wall thickness is present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Thickness": "245",
                                    "Wall-Construction": "4",
                                    "Wall-Thickness-Measured": "Y",
                                    "SAP-Alternative-Wall Wall-Thickness": "245",
                                    "SAP-Alternative-Wall Wall-Construction": "4",
                                    "SAP-Alternative-Wall Wall-Thickness-Measured": "N",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when all wall thickness measures are N and all wall thicknesses are present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Thickness": "245",
                                    "Wall-Construction": "4",
                                    "Wall-Thickness-Measured": "N",
                                    "SAP-Alternative-Wall Wall-Thickness": "245",
                                    "SAP-Alternative-Wall Wall-Construction": "4",
                                    "SAP-Alternative-Wall Wall-Thickness-Measured": "N",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when there are 10 or more habitable rooms VAL002" do
    let(:error) do
      {
        "code": "SCOTLAND_10_OR_MORE_HABITABLE_ROOMS_VAL002",
        "title":
          "High number of habitable rooms - 10 or more",
      }.freeze
    end

    it "allows lodgement when the number of habitable rooms is less than 10" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Habitable-Room-Count": "5",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when the number of habitable rooms is 10" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Habitable-Room-Count": "10",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when the number of habitable rooms is more than 10" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Habitable-Room-Count": "17",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when any roof construction is 4, 5 or 6 roof insulation location can be 5 VAL050" do
    let(:error) do
      {
        "code": "SCOTLAND_ROOF_INSULATION_LOCATION_CANNOT_BE_5_VAL050",
        "title":
          "Roof insulation location can only be 5 when roof construction is 4, 5 or 6",
      }.freeze
    end

    it "allows lodgement when all roof insulation location is not 5" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Roof-Insulation-Location": "4",
                                    "Roof-Construction": "2",
                                    "SAP-Alternative-Wall": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "allows lodgement when all roof insulation location is 5 and the roof construction is 4" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Roof-Insulation-Location": "5",
                                    "Roof-Construction": "4",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end

    it "raises an error when alternative wall thickness is less than 140 and corresponding construction is not park home or system built" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Roof-Insulation-Location": "5",
                                    "Roof-Construction": "2",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S])
    end
  end

  context "when the insulation is not give for a room in roof VAL051" do
    let(:error) do
      {
        "code": "SCOTLAND_INSULATION_IN_ROOM_IN_ROOF_IS_1_VAL051",
        "title":
          "The insulation for room in roof cannot be 1",
      }.freeze
    end

    it "allows lodgement when the insulation is not 1" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "SAP-Room-In-Roof Insulation": "2",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "allows lodgement when the insulation code is a string" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "SAP-Room-In-Roof Insulation": "ND",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when the insulation is 1" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "SAP-Room-In-Roof Insulation": "1",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end
  end

  context "when any either floor insulation thickness or floor u value is present VAL052" do
    let(:error) do
      {
        "code": "SCOTLAND_FLOOR_INSULATION_THICKNESS_AND_FLOOR_U_VALUE_CANNOT_BOTH_BE_PRESENT_VAL052",
        "title":
          "Either floor insulation thickness or floor u value can be present but not both. It is possible for neither to be present",
      }.freeze
    end

    it "allows lodgement when only floor insulation thickness is present" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Floor-U-Value": :delete,
                                    "Floor-Insulation-Thickness": "50mm",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "allows lodgement when only floor u value is present" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Floor-U-Value": "24",
                                    "Floor-Insulation-Thickness": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "allows lodgement when neither of the values are present" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Floor-U-Value": :delete,
                                    "Floor-Insulation-Thickness": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when both values are present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Floor-U-Value": "40",
                                    "Floor-Insulation-Thickness": "50mm",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end
  end

  context "when more than one value for roof insulation is present VAL053" do
    let(:error) do
      {
        "code": "SCOTLAND_ONLY_ONE_ROOF_INSULATION_VALUE_PERMITTED_VAL053",
        "title":
          "One one of the following should be present: Roof-Insulation-Thickness, Roof-U-Value, Rafter-Insulation-Thickness, Flat-Roof-Insulation-Thickness, Sloping-Ceiling-Insulation-Thickness",
      }.freeze
    end

    it "allows lodgement when only of the values is present" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Roof-Insulation-Thickness": "120mm",
                                    "Roof-U-Value": :delete,
                                    "Rafter-Insulation-Thickness": :delete,
                                    "Flat-Roof-Insulation-Thickness": :delete,
                                    "Sloping-Ceiling-Insulation-Thickness": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "allows lodgement when a different single value is present" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Roof-Insulation-Thickness": :delete,
                                    "Roof-U-Value": "4.3",
                                    "Rafter-Insulation-Thickness": :delete,
                                    "Flat-Roof-Insulation-Thickness": :delete,
                                    "Sloping-Ceiling-Insulation-Thickness": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when more than one value is present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Roof-Insulation-Thickness": "120mm",
                                    "Roof-U-Value": "4.3",
                                    "Rafter-Insulation-Thickness": :delete,
                                    "Flat-Roof-Insulation-Thickness": :delete,
                                    "Sloping-Ceiling-Insulation-Thickness": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when all values are present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Roof-Insulation-Thickness": "120mm",
                                    "Roof-U-Value": "4.3",
                                    "Rafter-Insulation-Thickness": "NI",
                                    "Flat-Roof-Insulation-Thickness": "NI",
                                    "Sloping-Ceiling-Insulation-Thickness": "NI",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when more than no value is present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Roof-Insulation-Thickness": :delete,
                                    "Roof-U-Value": :delete,
                                    "Rafter-Insulation-Thickness": :delete,
                                    "Flat-Roof-Insulation-Thickness": :delete,
                                    "Sloping-Ceiling-Insulation-Thickness": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end
  end

  context "when more than one value for wall insulation is present VAL054" do
    let(:error) do
      {
        "code": "SCOTLAND_ONLY_ONE_WALL_INSULATION_VALUE_PERMITTED_VAL054",
        "title":
          "One one of the following should be present: Wall-Insulation-Thickness, Wall-U-Value",
      }.freeze
    end

    it "allows lodgement when only of the values is present" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Insulation-Thickness": "120mm",
                                    "Wall-U-Value": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "allows lodgement when a different single value is present" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Wall-Insulation-Thickness": :delete,
                                    "Wall-U-Value": "4.3",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when more than one value is present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Insulation-Thickness": "120mm",
                                    "Wall-U-Value": "4.3",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when neither value is present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Wall-Insulation-Thickness": :delete,
                                    "Wall-U-Value": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end
  end

  context "when more than one value for room in roof insulation is present VAL055" do
    let(:error) do
      {
        "code": "SCOTLAND_ONLY_ONE_ROOM_IN_ROOF_INSULATION_VALUE_PERMITTED_VAL055",
        "title":
          "One one of the following should be present: Roof-Insulation-Thickness, Room-In-Roof-Details",
      }.freeze
    end

    it "allows lodgement when only of the values is present" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "SAP-Room-In-Roof Roof-Insulation-Thickness": "120mm",
                                    "SAP-Room-In-Roof Room-In-Roof-Details": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "allows lodgement when a different single value is present" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "SAP-Room-In-Roof Roof-Insulation-Thickness": :delete,
                                    "SAP-Room-In-Roof Room-In-Roof-Details": "{}",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when more than one value is present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "SAP-Room-In-Roof Roof-Insulation-Thickness": "120mm",
                                    "SAP-Room-In-Roof Room-In-Roof-Details": "{stuff_in_a_roof: 'things}",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when neither value is present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "SAP-Room-In-Roof Roof-Insulation-Thickness": :delete,
                                    "SAP-Room-In-Roof Room-In-Roof-Details": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end
  end

  context "when more than one value for alternative wall insulation is present VAL056" do
    let(:error) do
      {
        "code": "SCOTLAND_ONLY_ONE_ALTERNATIVE_WALL_INSULATION_VALUE_PERMITTED_VAL056",
        "title":
          "One one of the following should be present for an alternative wall: Wall-Insulation-Thickness, Wall-U-Value",
      }.freeze
    end

    it "allows lodgement when only of the values is present" do
      assert_rdsap_errors(expected_errors: [],
                          values: {
                            "SAP-Alternative-Wall Wall-Insulation-Thickness": "245",
                            "SAP-Alternative-Wall Wall-U-Value": :delete,
                            "Completion-Date": Date.today.to_s,
                            "Inspection-Date": Date.yesterday.to_s,
                          },
                          country_code: [:S],
                          file_name: "lodgement_rules_example_flat")
    end

    it "allows lodgement when a different single value is present" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "SAP-Alternative-Wall Wall-Insulation-Thickness": :delete,
                                    "SAP-Alternative-Wall Wall-U-Value": "3",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "lodgement_rules_example_flat")
    end

    it "raises an error when more than one value is present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "SAP-Alternative-Wall Wall-Insulation-Thickness": "35",
                                    "SAP-Alternative-Wall Wall-U-Value": "3",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "lodgement_rules_example_flat")
    end

    it "raises an error when neither value is present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "SAP-Alternative-Wall Wall-Insulation-Thickness": :delete,
                                    "SAP-Alternative-Wall Wall-U-Value": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "lodgement_rules_example_flat")
    end
  end

  context "when more than one value for main heating is present VAL057" do
    let(:error) do
      {
        "code": "SCOTLAND_ONLY_ONE_MAIN_HEATING_VALUE_PERMITTED_VAL057",
        "title":
          "One one of the following should be present for main heating: Main-Heating-Index-Number, SAP-Main-Heating-Code",
      }.freeze
    end

    it "allows lodgement when only of the values is present" do
      assert_rdsap_errors(expected_errors: [],
                          values: {
                            "Main-Heating-Index-Number": "245",
                            "SAP-Main-Heating-Code": :delete,
                            "Completion-Date": Date.today.to_s,
                            "Inspection-Date": Date.yesterday.to_s,
                          },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "allows lodgement when a different single value is present" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Main-Heating-Index-Number": :delete,
                                    "SAP-Main-Heating-Code": "245",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when more than one value is present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Main-Heating-Index-Number": "321",
                                    "SAP-Main-Heating-Code": "245",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when neither value is present" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Main-Heating-Index-Number": :delete,
                                    "SAP-Main-Heating-Code": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end
  end

  context "when main fuel type is 0 VAL059" do
    let(:error) do
      {
        "code": "SCOTLAND_MAIN_HEATING_CODE_MUST_BE_699_OR_310_VAL059",
        "title":
          "Main-Fuel-Type may only be 0 when Main-Heating-Code is either 699 and 310",
      }.freeze
    end

    it "allows lodgement when main-fuel-type is not 0" do
      assert_rdsap_errors(expected_errors: [],
                          values: {
                            "Main-Fuel-Type": "4",
                            "SAP-Main-Heating-Code": "333",
                            "Main-Heating-Index-Number": :delete,
                            "Completion-Date": Date.today.to_s,
                            "Inspection-Date": Date.yesterday.to_s,
                          },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "allows lodgement when main-fuel-type is 0 but main-heating-code is either 310 or 699" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Main-Fuel-Type": "0",
                                    "SAP-Main-Heating-Code": "310",
                                    "Main-Heating-Index-Number": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when main-fuel-type is 0 but main-heating-code is not 310 or 699" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Main-Fuel-Type": "0",
                                    "SAP-Main-Heating-Code": "230",
                                    "Main-Heating-Index-Number": :delete,
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end
  end

  context "when water heating fuel is 0 VAL060" do
    let(:error) do
      {
        "code": "SCOTLAND_WATER_HEATING_CODE_MUST_BE_999_OR_953_VAL060",
        "title":
          "Water-Heating-Fuel may only be 0 when Water-Heating-Code is either 999 and 953",
      }.freeze
    end

    it "allows lodgement when water-heating-fuel is not 0" do
      assert_rdsap_errors(expected_errors: [],
                          values: {
                            "Water-Heating-Fuel": "4",
                            "Water-Heating-Code": "333",
                            "Completion-Date": Date.today.to_s,
                            "Inspection-Date": Date.yesterday.to_s,
                          },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "allows lodgement when water-heating-fuel is 0 but water-heating-code is either 953 - 999" do
      assert_rdsap_errors(expected_errors: [],
                          values: { "Water-Heating-Fuel": "0",
                                    "Water-Heating-Code": "999",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
    end

    it "raises an error when water-heating-fuel is 0 but water-heating-code is not 953 or 999" do
      assert_rdsap_errors(expected_errors: [error],
                          values: { "Water-Heating-Fuel": "0",
                                    "Water-Heating-Code": "943",
                                    "Completion-Date": Date.today.to_s,
                                    "Inspection-Date": Date.yesterday.to_s },
                          country_code: [:S],
                          file_name: "house_epc")
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
      assert_rdsap_errors(expected_errors: [error], values: { "Address/Postcode": "SW1A 2AA",
                                                              "Inspection-Date": Date.yesterday.to_s,
                                                              "Completion-Date": Date.today.to_s,
                                                              "Registration-Date": Date.today.to_s }, country_code: [:E])
    end

    it "returns an error if the address is NI" do
      assert_rdsap_errors(expected_errors: [error], values: { "Address/Postcode": "BT3 9EP",
                                                              "Inspection-Date": Date.yesterday.to_s,
                                                              "Completion-Date": Date.today.to_s,
                                                              "Registration-Date": Date.today.to_s }, country_code: [:N])
    end

    it "returns an error if the address is Wales" do
      assert_rdsap_errors(expected_errors: [error], values: { "Address/Postcode": "CF99 1NA",
                                                              "Inspection-Date": Date.yesterday.to_s,
                                                              "Completion-Date": Date.today.to_s,
                                                              "Registration-Date": Date.today.to_s }, country_code: [:W])
    end

    it "returns an error if the address is JE" do
      assert_rdsap_errors(expected_errors: [error], values: { "Address/Postcode": "JE3 6HW",
                                                              "Inspection-Date": Date.yesterday.to_s,
                                                              "Completion-Date": Date.today.to_s,
                                                              "Registration-Date": Date.today.to_s }, country_code: [:L])
    end

    it "returns an error if the address is GY" do
      assert_rdsap_errors(expected_errors: [error], values: { "Address/Postcode": "GY7 9QS",
                                                              "Inspection-Date": Date.yesterday.to_s,
                                                              "Completion-Date": Date.today.to_s,
                                                              "Registration-Date": Date.today.to_s }, country_code: [:L])
    end

    it "returns an error if the address is IM" do
      assert_rdsap_errors(expected_errors: [error], values: { "Address/Postcode": "IM7 3BZ",
                                                              "Inspection-Date": Date.yesterday.to_s,
                                                              "Completion-Date": Date.today.to_s,
                                                              "Registration-Date": Date.today.to_s }, country_code: [:L])
    end

    it "returns an error if the country code is in England" do
      assert_rdsap_errors(expected_errors: [error], values: { "Country-Code": "ENG",
                                                              "Inspection-Date": Date.yesterday.to_s,
                                                              "Completion-Date": Date.today.to_s,
                                                              "Registration-Date": Date.today.to_s }, country_code: [:E])
    end

    it "returns an error if the country code is in Wales" do
      assert_rdsap_errors(expected_errors: [error], values: { "Country-Code": "WLS",
                                                              "Inspection-Date": Date.yesterday.to_s,
                                                              "Completion-Date": Date.today.to_s,
                                                              "Registration-Date": Date.today.to_s }, country_code: [:W])
    end

    it "returns an error if the country code is in England or Wales" do
      assert_rdsap_errors(expected_errors: [error], values: { "Country-Code": "EAW",
                                                              "Inspection-Date": Date.yesterday.to_s,
                                                              "Completion-Date": Date.today.to_s,
                                                              "Registration-Date": Date.today.to_s }, country_code: [:W])
    end

    it "returns no error if the country code is in Scotland" do
      assert_rdsap_errors(expected_errors: [], values: { "Country-Code": "SCT",
                                                         "Inspection-Date": Date.yesterday.to_s,
                                                         "Completion-Date": Date.today.to_s,
                                                         "Registration-Date": Date.today.to_s }, country_code: [:S])
    end

    it "returns no error if the address is in Scotland" do
      assert_rdsap_errors(expected_errors: [], values: { "Address/Postcode": "EH1 2NG",
                                                         "Inspection-Date": Date.yesterday.to_s,
                                                         "Completion-Date": Date.today.to_s,
                                                         "Registration-Date": Date.today.to_s }, country_code: [:S])
    end

    it "returns no error if the postcode crosses the English/Scottish border" do
      assert_rdsap_errors(expected_errors: [], values: { "Address/Postcode": "TD15 1UZ",
                                                         "Inspection-Date": Date.yesterday.to_s,
                                                         "Completion-Date": Date.today.to_s,
                                                         "Registration-Date": Date.today.to_s }, country_code: %i[E S])
    end
  end
end
