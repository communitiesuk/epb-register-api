require_relative "../../shared_context/shared_lodgement"

describe LodgementRules::DomesticCommon, :set_with_timecop do
  include_context "when lodging XML"
  let(:docs_under_test) { %w[RdSAP-Schema-20.0.0 RdSAP-Schema-NI-20.0.0] }

  it "returns an empty list for a valid file" do
    country_lookup = Domain::CountryLookup.new(country_codes: [:E])

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

  context "when the habitable room count has an illegal value" do
    let(:error) do
      {
        "code": "MUST_HAVE_HABITABLE_ROOMS",
        "title":
          '"Habitable-Room-Count" must be an integer and must be greater than or equal to 1',
      }.freeze
    end

    it "returns an error if the habitable room count is zero" do
      assert_errors(expected_errors: [error], values: { "Habitable-Room-Count": "0" })
    end

    it "returns an error if the habitable room count is negative" do
      assert_errors(expected_errors: [error], values: { "Habitable-Room-Count": "-2" })
    end
  end

  context "when energy ratings and environmental impacts are zero" do
    let(:error) do
      {
        "code": "RATINGS_MUST_BE_POSITIVE",
        "title":
          '"Energy-Rating-Current", "Energy-Rating-Potential", "Environmental-Impact-Current" and "Environmental-Impact-Potential" must be greater than 0',
      }.freeze
    end

    it "returns an error if Energy Rating Current is 0" do
      assert_errors(expected_errors: [error], values: { "Energy-Rating-Current": "0" })
    end

    it "returns an error if Energy Rating Potential is 0" do
      assert_errors(expected_errors: [error], values: { "Energy-Rating-Potential": "0" })
    end

    it "returns an error if Environmental-Impact-Current is 0" do
      assert_errors(expected_errors: [error], values: { "Environmental-Impact-Current": "0" })
    end

    it "returns an error if Environmental-Impact-Potential is 0" do
      assert_errors(expected_errors: [error], values: { "Environmental-Impact-Potential": "0" })
    end
  end

  context "when an element that needs a description is missing one" do
    let(:error) do
      {
        "code": "MUST_HAVE_DESCRIPTION",
        "title":
          '"Description" for parent node "Wall", "Walls", "Roof", "Floor", "Window", "Windows", "Main-Heating", "Main-Heating-Controls", "Hot-Water", "Lighting" and "Secondary-Heating" must not be equal to the parent node name, ignoring case',
      }.freeze
    end

    it "returns an error if Wall has a description of wall" do
      assert_errors(expected_errors: [error], values: { "Wall/Description": "wall" })
    end

    it "returns an error if Roof has a description of roof" do
      assert_errors(expected_errors: [error], values: { "Roof/Description": "roof" })
    end

    it "returns an error if Floor has a description of floor" do
      assert_errors(expected_errors: [error], values: { "Floor/Description": "floor" })
    end

    it "returns an error if Window has a description of window" do
      assert_errors(expected_errors: [error], values: { "Window/Description": "window" })
    end

    it "returns an error if Main-Heating has a description of main-heating" do
      assert_errors(expected_errors: [error], values: { "Main-Heating/Description": "main-heating" })
    end

    it "returns an error if Main-Heating-Controls has a description of main-heating-controls" do
      assert_errors(expected_errors: [error], values: { "Main-Heating-Controls/Description": "main-heating-controls" })
    end

    it "returns an error if Hot-Water has a description of hot-water" do
      assert_errors(expected_errors: [error], values: { "Hot-Water/Description": "hot-water" })
    end

    it "returns an error if Lighting has a description of lighting" do
      assert_errors(expected_errors: [error], values: { "Lighting/Description": "lighting" })
    end

    it "returns an error if Secondary-Heating has a description of secondary-heating" do
      assert_errors(expected_errors: [error], values: { "Secondary-Heating/Description": "secondary-heating" })
    end
  end

  context "when floor area has an illegal value" do
    let(:error) do
      {
        "code": "SAP_FLOOR_AREA_RANGE",
        "title":
          '"Total-Floor-Area" within "SAP-Floor-Dimension" must be greater than 0 and less than or equal to 3000',
      }.freeze
    end

    it "returns an error if the floor area is 0" do
      assert_errors(expected_errors: [error], values: { "SAP-Floor-Dimension/Total-Floor-Area": "0" })
    end

    it "returns an error if the floor area is negative" do
      assert_errors(expected_errors: [error], values: { "SAP-Floor-Dimension/Total-Floor-Area": "-6" })
    end

    it "returns an error if the floor area is more than 3000" do
      assert_errors(expected_errors: [error], values: { "SAP-Floor-Dimension/Total-Floor-Area": "3001" })
    end

    it "returns no errors if floor area is 100" do
      assert_errors(expected_errors: [], values: { "SAP-Floor-Dimension/Total-Floor-Area": "100" })
    end

    it "returns no errors if floor area is 0.45" do
      assert_errors(expected_errors: [], values: { "SAP-Floor-Dimension/Total-Floor-Area": "0.45" })
    end
  end

  context "when 'Level' is greater than 1 and 'Building-Part-Number' is 1" do
    let(:error) do
      {
        "code": "GROUND_FLOOR_HEAT_LOSS_ON_UPPER_FLOOR",
        "title":
          'If "Level" is greater than 1 and "Building-Part-Number" is equal to 1 then "Floor-Heat-Loss" must not be equal to 7',
      }.freeze
    end

    it "returns an error when the described scenario is triggered (Floor-Heat-Loss being given as 7)" do
      assert_errors(expected_errors: [error], values: { "Level": "2", "Building-Part-Number": "1", "Floor-Heat-Loss": "7" })
    end
  end

  context "when 'Water-Heating-Code' has a value of 903" do
    let(:error) do
      {
        "code": "SUPPLY_IMMERSION_HEATER_TYPE",
        "title":
          'If "Water-Heating-Code" is equal to 903 then "Immersion-Heating-Type" must not be equal to \'NA\'',
      }.freeze
    end

    it "returns an error when the described scenario is triggered (Immersion-Heating-Type is 'NA')" do
      assert_errors(expected_errors: [error], values: { "Water-Heating-Code": "903", "Immersion-Heating-Type": "NA" })
    end
  end

  context "when 'Main-Heating-Category' is 2 and 'Main-Fuel-Type' is 17, 18, 26, 27, 28, 34, 35, 36, 37 or 51" do
    let(:error) do
      {
        "code": "SUPPLY_BOILER_FLUE_TYPE",
        "title":
          'If "Main-Heating-Category" is equal to 2 and "Main-Fuel-Type" is equal to 17, 18, 26, 27, 28, 34, 35, 36, 37 or 51 then "Boiler-Flue-Type" must be supplied',
      }.freeze
    end

    it "returns no errors when main fuel type is 17 but boiler flue type is present" do
      assert_errors(expected_errors: [], values: { "Main-Heating-Category": "2", "Main-Fuel-Type": "17" })
    end

    it "returns an error when boiler flue type is missing" do
      relevant_fuel_types = %w[17 18 26 27 28 34 35 36 37 51]

      relevant_fuel_types.each do |fuel_type|
        assert_errors(expected_errors: [error], values: {
          "Main-Heating-Category": "2",
          "Boiler-Flue-Type": :delete,
          "Main-Fuel-Type": fuel_type,
        })
      end
    end
  end

  describe "dates in future scenarios" do
    let(:rule_under_test_error) do
      {
        "code": "DATES_CANT_BE_IN_FUTURE",
        "title":
          '"Inspection-Date", "Registration-Date" and "Completion-Date" must not be in the future',
      }.freeze
    end

    it "Allows an inspection date that is today" do
      assert_errors(expected_errors: [], values: {
        "Inspection-Date": Date.today.to_s,
        "Registration-Date": Date.today.to_s,
        "Completion-Date": Date.today.to_s,
      })
    end

    it "returns an error when any of the dates are in the future" do
      assert_errors(expected_errors: [rule_under_test_error], values: {
        "Inspection-Date": Date.tomorrow.to_s,
        "Registration-Date": Date.tomorrow.to_s,
        "Completion-Date": Date.tomorrow.to_s,
      })
    end

    it "returns an error when completion date is in the future" do
      assert_errors(expected_errors: [rule_under_test_error], values:
                    {
                      "Inspection-Date": Date.today.to_s,
                      "Completion-Date": Date.tomorrow.to_s,
                      "Registration-Date": Date.tomorrow.to_s,
                    })
    end
  end

  describe "dates in range scenarios" do
    let(:rule_under_test_error) do
      {
        "code": "DATES_IN_RANGE",
        "title":
          '"Inspection-Date", "Registration-Date" and "Completion-Date" must not be more than 18 months ago',
      }.freeze
    end

    it "Allows an inspection date that is today" do
      assert_errors(expected_errors: [], values:
                    {
                      "Inspection-Date": Date.today.to_s,
                      "Registration-Date": Date.today.to_s,
                      "Completion-Date": Date.today.to_s,
                    })
    end

    it "returns an error when any of the dates are more than 18 months ago" do
      assert_errors(expected_errors: [rule_under_test_error], values: {
        "Inspection-Date": Date.today.prev_month(19).to_s,
        "Registration-Date": Date.today.prev_month(19).to_s,
        "Completion-Date": Date.today.prev_month(19).to_s,
      })
    end
  end

  context "when 'Meter-Type' is 2" do
    let(:error) do
      {
        "code": "INVALID_HEATING_FOR_SINGLE_METER",
        "title":
          'If "Meter-Type" is equal to 2 then "SAP-Main-Heating-Code" must not be equal to 401, 402, 404, 408, 409, 421 or 422',
      }.freeze
    end

    it "Rejects single meter with invalid heating code" do
      relevant_heating_codes = %w[401 402 404 408 409 421 422]

      relevant_heating_codes.each do |heating_code|
        assert_errors(expected_errors: [error], values: {
          "Meter-Type": "2", "SAP-Main-Heating-Code": heating_code
        })
      end
    end
  end

  describe "insulation thickness scenarios" do
    let(:error) do
      {
        "code": "SUPPLY_ROOF_U_VALUE_OR_INSULATION_THICKNESS",
        "title":
          'Only one of "Roof-Insulation-Thickness", "Rafter-Insulation-Thickness", "Flat-Roof-Insulation-Thickness", "Sloping-Ceiling-Insulation-Thickness" or "Roof-U-Value" may be supplied',
      }.freeze
    end

    it "Accepts assessment where only one value is supplied" do
      assert_errors(expected_errors: [], values: {})
    end

    it "accepts assessment where Roof-Insulation-Thickness is supplied inside SAP-Room-In-Roof as well" do
      %w[
        12mm
        25mm
        50mm
        75mm
        100mm
        150mm
        200mm
        250mm
        270mm
        300mm
        350mm
        400mm
        ND
      ].each do |value|
        assert_errors(
          expected_errors: [],
          values: { "SAP-Building-Part Roof-Insulation-Thickness": :delete },
          new_nodes: [
            {
              selector: "Roof-Insulation-Location",
              xml:
                "<Rafter-Insulation-Thickness>AB</Rafter-Insulation-Thickness>",
            },
            {
              selector: "Roof-Room-Connected",
              xml:
                "<Roof-Insulation-Thickness>#{
                  value
                }</Roof-Insulation-Thickness>",
            },
          ],
        )
      end
    end

    it "Rejects assessment where rafter and roof insulation are supplied" do
      assert_errors(
        expected_errors: [error],
        values: {},
        new_nodes: [
          {
            selector: "Roof-Insulation-Thickness",
            xml: "<Rafter-Insulation-Thickness>2</Rafter-Insulation-Thickness>",
          },
        ],
      )
    end

    it "Rejects assessment where roof and flat roof insulation are supplied" do
      assert_errors(
        expected_errors: [error],
        values: {},
        new_nodes: [
          {
            selector: "Roof-Insulation-Thickness",
            xml:
              "<Flat-Roof-Insulation-Thickness>2</Flat-Roof-Insulation-Thickness>",
          },
        ],
      )
    end

    it "Rejects assessment where roof and sloping ceiling insulation are supplied" do
      assert_errors(
        expected_errors: [error],
        values: {},
        new_nodes: [
          {
            selector: "Roof-Insulation-Thickness",
            xml:
              "<Sloping-Ceiling-Insulation-Thickness>2</Sloping-Ceiling-Insulation-Thickness>",
          },
        ],
      )
    end

    it "Rejects assessment where roof and roof u value are supplied" do
      assert_errors(
        expected_errors: [error],
        values: {},
        new_nodes: [
          {
            selector: "Roof-Insulation-Thickness",
            xml: "<Roof-U-Value>2</Roof-U-Value>",
          },
        ],
      )
    end

    it "Rejects assessment with more than 2 types of roof insulation" do
      assert_errors(
        expected_errors: [error],
        values: {},
        new_nodes: [
          {
            selector: "Roof-Insulation-Thickness",
            xml: "<Roof-U-Value>2</Roof-U-Value>",
          },
          {
            selector: "Roof-Insulation-Thickness",
            xml:
              "<Sloping-Ceiling-Insulation-Thickness>2</Sloping-Ceiling-Insulation-Thickness>",
          },
          {
            selector: "Roof-Insulation-Thickness",
            xml: "<Rafter-Insulation-Thickness>2</Rafter-Insulation-Thickness>",
          },
        ],
      )
    end
  end

  context "when 'Roof-Room-Connected' is 'Y' or 'y'" do
    let(:error) do
      {
        "code": "SUPPLY_MULTIPLE_BUILDING_PARTS",
        "title":
          'If "Roof-Room-Connected" is equal to \'Y\' or \'y\' then more than one "SAP-Building-Part" must be supplied',
      }.freeze
    end

    let(:building_part_xml) do
      '
        <SAP-Building-Part>
        <Building-Part-Number>1</Building-Part-Number>
          <Roof-Insulation-Location>2</Roof-Insulation-Location>
       </SAP-Building-Part>
       '
    end

    it "returns no errors when roof room connected is y and more than one building part supplied" do
      assert_errors(
        expected_errors: [],
        values: { "Roof-Room-Connected": "Y" },
        new_nodes: [{ selector: "SAP-Building-Part", xml: building_part_xml }],
      )
    end

    it "returns no errors when roof room connected is n and only building part supplied" do
      assert_errors(expected_errors: [], values: { "Roof-Room-Connected": "N" })
    end

    it "returns error when roof room connected is y and only building part supplied" do
      assert_errors(expected_errors: [error], values: { "Roof-Room-Connected": "Y" })
    end
  end

  context "when the inspection date is later than the completion date" do
    let(:error) do
      {
        "code": "INSPECTION_DATE_LATER_THAN_COMPLETION_DATE",
        "title":
          'The "Completion-Date" must be equal to or later than "Inspection-Date"',
      }.freeze
    end

    it "allows lodgement when the Completion-Date is after the Inspection-Date" do
      assert_errors(expected_errors: [], values: { "Inspection-Date": Date.yesterday.to_s,
                                                   "Completion-Date": Date.today.to_s,
                                                   "Registration-Date": Date.today.to_s })
    end

    it "allows lodgement when the Inspection-Date and the Completion-Date are equal" do
      assert_errors(expected_errors: [], values: { "Inspection-Date": Date.today.to_s,
                                                   "Completion-Date": Date.today.to_s,
                                                   "Registration-Date": Date.today.to_s  })
    end

    it "throws an error when the Inspection-Date is later than the Completion-Date" do
      assert_errors(expected_errors: [error], values: {   "Inspection-Date": Date.today.to_s,
                                                          "Completion-Date": Date.yesterday.to_s,
                                                          "Registration-Date": Date.today.to_s })
    end
  end

  context "when the completion date is later than the registration date" do
    let(:error) do
      {
        "code": "COMPLETION_DATE_LATER_THAN_REGISTRATION_DATE",
        "title":
          'The "Completion-Date" must be before or equal to the "Registration-Date"',
      }.freeze
    end

    it "allows lodgement when the Registration-Date is after the Completion-Date" do
      assert_errors(expected_errors: [], values: { "Completion-Date": Date.yesterday.to_s,
                                                   "Registration-Date": Date.today.to_s  })
    end

    it "allows lodgement when the Completion-Date and the Registration-Date are equal" do
      assert_errors(expected_errors: [], values: { "Completion-Date": Date.today.to_s,
                                                   "Registration-Date": Date.today.to_s })
    end

    it "throws an error when the Completion-Date is later than the Registration-Date" do
      assert_errors(expected_errors: [error], values: { "Completion-Date": Date.today.to_s,
                                                        "Registration-Date": Date.yesterday.to_s })
    end
  end

  context "when the inspection date is later than the completion date, which is in turn later than the registration date" do
    let(:inspection_date_error) do
      {
        "code": "INSPECTION_DATE_LATER_THAN_COMPLETION_DATE",
        "title":
          'The "Completion-Date" must be equal to or later than "Inspection-Date"',
      }.freeze
    end
    let(:completion_date_error) do
      {
        "code": "COMPLETION_DATE_LATER_THAN_REGISTRATION_DATE",
        "title":
          'The "Completion-Date" must be before or equal to the "Registration-Date"',
      }.freeze
    end

    it "allows lodgement when the Completion-Date is after the Inspection-Date and the Registration-Date is after the Completion-Date" do
      assert_errors(expected_errors: [], values: { "Inspection-Date": Date.yesterday.prev_day.to_s,
                                                   "Completion-Date": Date.yesterday.to_s,
                                                   "Registration-Date": Date.today.to_s })
    end

    it "allows lodgement when all the dates are equal" do
      assert_errors(expected_errors: [], values: { "Inspection-Date": Date.today.to_s,
                                                   "Completion-Date": Date.today.to_s,
                                                   "Registration-Date": Date.today.to_s })
    end

    it "throws the Inspection error when the Completion-Date is before the Inspection-Date" do
      assert_errors(expected_errors: [inspection_date_error], values: { "Inspection-Date": Date.yesterday.to_s,
                                                                        "Completion-Date": Date.yesterday.prev_day.to_s,
                                                                        "Registration-Date": Date.today.to_s })
    end

    it "throws the Completion error when the Registration-Date is before the Completion-Date" do
      assert_errors(expected_errors: [completion_date_error], values: { "Inspection-Date": Date.yesterday.prev_day.to_s,
                                                                        "Completion-Date": Date.today.to_s,
                                                                        "Registration-Date": Date.yesterday.to_s })
    end

    it "throws both errors when both the Inspection-Date is later than the Completion-Date and when the Completion-Date is later than the Registration-Date" do
      assert_errors(expected_errors: [inspection_date_error, completion_date_error], values: { "Inspection-Date": Date.today.to_s,
                                                                                               "Completion-Date": Date.yesterday.to_s,
                                                                                               "Registration-Date": Date.yesterday.prev_day.to_s })
    end

    it "throws Completion error when the Registration-Date is before the Inspection- and Completion-Date" do
      assert_errors(expected_errors: [completion_date_error], values: { "Inspection-Date": Date.yesterday.to_s,
                                                                        "Completion-Date": Date.today.to_s,
                                                                        "Registration-Date": Date.yesterday.prev_day.to_s })
    end
  end

  context "when the address is not in England, Wales, or Northern Ireland" do
    let(:error) do
      {
        "code": "INVALID_COUNTRY",
        "title": "Property address must be in England, Wales, or Northern Ireland",
      }.freeze
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

    it "returns an error if the address is in Scotland" do
      assert_errors(expected_errors: [error], values: { "Address/Postcode": "TD14 5TY" }, country_code: [:S])
    end

    it "returns an error if the country code is Scotland" do
      assert_errors(expected_errors: [error], values: { "Country-Code": "SCT" }, country_code: [:S])
    end

    it "returns no error if the address is in England" do
      assert_errors(expected_errors: [], values: { "Address/Postcode": "SW1A 2AA" }, country_code: [:E])
    end

    it "returns no error if the address is in Northern Ireland" do
      assert_errors(expected_errors: [], values: { "Address/Postcode": "BT3 9EP" }, country_code: [:N])
    end

    it "returns no error if the address is in Wales" do
      assert_errors(expected_errors: [], values: { "Address/Postcode": "LL65 1DQ" }, country_code: [:W])
    end

    it "returns no error if the postcode crosses the English/Scottish border" do
      assert_errors(expected_errors: [], values: { "Address/Postcode": "TD15 1UZ" }, country_code: %i[E S])
    end

    it "returns no error if the country code is England or Wales" do
      assert_errors(expected_errors: [], values:  { "Country-Code": "EAW" }, country_code: %i[E W])
    end

    it "returns no error if the address is Northern Ireland" do
      assert_errors(expected_errors: [], values:  { "Country-Code": "NIR" }, country_code: [:N])
    end
  end
end
