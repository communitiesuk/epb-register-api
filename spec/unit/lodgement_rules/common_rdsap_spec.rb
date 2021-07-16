describe LodgementRules::DomesticCommon, set_with_timecop: true do
  let(:docs_under_test) { %w[RdSAP-Schema-20.0.0 RdSAP-Schema-NI-20.0.0] }

  def assert_errors(expected_errors, values = nil, new_nodes = [])
    docs_under_test.each do |doc|
      xml_doc = Nokogiri.XML(Samples.xml(doc))

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

      wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, doc, false)
      adapter = wrapper.get_view_model
      errors = described_class.new.validate(adapter)
      expect(errors).to match_array(expected_errors)
    end
  end

  it "Returns an empty list for a valid file" do
    docs_under_test.each do |doc|
      wrapper =
        ViewModel::Factory.new.create(
          Nokogiri.XML(Samples.xml(doc)).to_xml,
          doc,
          false,
        )
      adapter = wrapper.get_view_model
      errors = described_class.new.validate(adapter)
      expect(errors).to eq([])
    end
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
      assert_errors([error], { "Habitable-Room-Count": "6.2" })
    end

    it "returns an error if the habitable room count is zero" do
      assert_errors([error], { "Habitable-Room-Count": "0" })
    end

    it "returns an error if the habitable room count is negative" do
      assert_errors([error], { "Habitable-Room-Count": "-2" })
    end
  end

  context "RATINGS_MUST_BE_POSITIVE" do
    let(:error) do
      {
        "code": "RATINGS_MUST_BE_POSITIVE",
        "title":
          '"Energy-Rating-Current", "Energy-Rating-Potential", "Environmental-Impact-Current" and "Environmental-Impact-Potential" must be greater than 0',
      }.freeze
    end

    it "returns an error if Energy Rating Current is 0" do
      assert_errors([error], { "Energy-Rating-Current": "0" })
    end

    it "returns an error if Energy Rating Potential is 0" do
      assert_errors([error], { "Energy-Rating-Potential": "0" })
    end

    it "returns an error if Environmental-Impact-Current is 0" do
      assert_errors([error], { "Environmental-Impact-Current": "0" })
    end

    it "returns an error if Environmental-Impact-Potential is 0" do
      assert_errors([error], { "Environmental-Impact-Potential": "0" })
    end
  end

  context "MUST_HAVE_DESCRIPTION" do
    let(:error) do
      {
        "code": "MUST_HAVE_DESCRIPTION",
        "title":
          '"Description" for parent node "Wall", "Walls", "Roof", "Floor", "Window", "Windows", "Main-Heating", "Main-Heating-Controls", "Hot-Water", "Lighting" and "Secondary-Heating" must not be equal to the parent node name, ignoring case',
      }.freeze
    end

    it "returns an error if Wall has a description of wall" do
      assert_errors([error], { "Wall/Description": "wall" })
    end

    it "returns an error if Roof has a description of roof" do
      assert_errors([error], { "Roof/Description": "roof" })
    end

    it "returns an error if Floor has a description of floor" do
      assert_errors([error], { "Floor/Description": "floor" })
    end

    it "returns an error if Window has a description of window" do
      assert_errors([error], { "Window/Description": "window" })
    end

    it "returns an error if Main-Heating has a description of main-heating" do
      assert_errors([error], { "Main-Heating/Description": "main-heating" })
    end

    it "returns an error if Main-Heating-Controls has a description of main-heating-controls" do
      assert_errors(
        [error],
        { "Main-Heating-Controls/Description": "main-heating-controls" },
      )
    end

    it "returns an error if Hot-Water has a description of hot-water" do
      assert_errors([error], { "Hot-Water/Description": "hot-water" })
    end

    it "returns an error if Lighting has a description of lighting" do
      assert_errors([error], { "Lighting/Description": "lighting" })
    end

    it "returns an error if Secondary-Heating has a description of secondary-heating" do
      assert_errors(
        [error],
        { "Secondary-Heating/Description": "secondary-heating" },
      )
    end
  end

  context "SAP_FLOOR_AREA_RANGE" do
    let(:error) do
      {
        "code": "SAP_FLOOR_AREA_RANGE",
        "title":
          '"Total-Floor-Area" within "SAP-Floor-Dimension" must be greater than 0 and less than or equal to 3000',
      }.freeze
    end

    it "returns an error if the floor area is 0" do
      assert_errors([error], { "SAP-Floor-Dimension/Total-Floor-Area": "0" })
    end

    it "returns an error if the floor area is negative" do
      assert_errors([error], { "SAP-Floor-Dimension/Total-Floor-Area": "-6" })
    end

    it "returns an error if the floor area is more than 3000" do
      assert_errors([error], { "SAP-Floor-Dimension/Total-Floor-Area": "3001" })
    end

    it "returns no errors if floor area is 100" do
      assert_errors([], { "SAP-Floor-Dimension/Total-Floor-Area": "100" })
    end

    it "returns no errors if floor area is 0.45" do
      assert_errors([], { "SAP-Floor-Dimension/Total-Floor-Area": "0.45" })
    end
  end

  context "GROUND_FLOOR_HEAT_LOSS_ON_UPPER_FLOOR" do
    let(:error) do
      {
        "code": "GROUND_FLOOR_HEAT_LOSS_ON_UPPER_FLOOR",
        "title":
          'If "Level" is greater than 1 and "Building-Part-Number" is equal to 1 then "Floor-Heat-Loss" must not be equal to 7',
      }.freeze
    end

    it "returns an error when the described scenario is triggered" do
      assert_errors(
        [error],
        { "Level": "2", "Building-Part-Number": "1", "Floor-Heat-Loss": "7" },
      )
    end
  end

  context "SUPPLY_IMMERSION_HEATER_TYPE" do
    let(:error) do
      {
        "code": "SUPPLY_IMMERSION_HEATER_TYPE",
        "title":
          'If "Water-Heating-Code" is equal to 903 then "Immersion-Heating-Type" must not be equal to \'NA\'',
      }.freeze
    end

    it "returns an error when the described scenario is triggered" do
      assert_errors(
        [error],
        { "Water-Heating-Code": "903", "Immersion-Heating-Type": "NA" },
      )
    end
  end

  context "SUPPLY_BOILER_FLUE_TYPE" do
    let(:error) do
      {
        "code": "SUPPLY_BOILER_FLUE_TYPE",
        "title":
          'If "Main-Heating-Category" is equal to 2 and "Main-Fuel-Type" is equal to 17, 18, 26, 27, 28, 34, 35, 36, 37 or 51 then "Boiler-Flue-Type" must be supplied',
      }.freeze
    end

    it "returns no errors when main fuel type is 17 but boiler flue type is present" do
      assert_errors(
        [],
        { "Main-Heating-Category": "2", "Main-Fuel-Type": "17" },
      )
    end

    it "returns an error when boiler flue type is missing" do
      relevant_fuel_types = %w[17 18 26 27 28 34 35 36 37 51]

      relevant_fuel_types.each do |fuel_type|
        assert_errors(
          [error],
          {
            "Main-Heating-Category": "2",
            "Boiler-Flue-Type": :delete,
            "Main-Fuel-Type": fuel_type,
          },
        )
      end
    end
  end

  context "DATES_IN_RANGE" do
    let(:rule_under_test_error) do
      {
        "code": "DATES_IN_RANGE",
        "title":
          '"Inspection-Date", "Registration-Date" and "Completion-Date" must not be in the future and must not be more than 18 months ago',
      }.freeze
    end
    let(:expected_inspection_test_error) do
      {
        "code": "INSPECTION_DATE_LATER_THAN_COMPLETION_DATE",
        "title":
          'The "Completion-Date" must be equal to or later than "Inspection-Date"',
      }.freeze
    end
    let(:expected_completion_test_error) do
      {
        "code": "COMPLETION_DATE_LATER_THAN_REGISTRATION_DATE",
        "title":
          'The "Completion-Date" must be before or equal to the "Registration-Date"',
      }.freeze
    end

    it "Allows an inspection date that is today" do
      assert_errors([expected_inspection_test_error, expected_completion_test_error], { "Inspection-Date": Date.today.to_s })
    end

    it "returns an error when inspection date is in the future" do
      assert_errors([rule_under_test_error], { "Inspection-Date": Date.tomorrow.to_s })
    end

    it "returns an error when inspection date is more than 18 months ago" do
      assert_errors(
        [rule_under_test_error],
        { "Inspection-Date": Date.today.prev_month(19).to_s },
      )
    end

    it "returns an error when registration date is in the future" do
      assert_errors([rule_under_test_error], { "Registration-Date": Date.tomorrow.to_s })
    end

    it "returns an error when registration date is more than 18 months ago" do
      assert_errors(
        [rule_under_test_error],
        { "Registration-Date": Date.today.prev_month(19).to_s },
      )
    end

    it "returns an error when completion date is in the future" do
      assert_errors([rule_under_test_error], { "Completion-Date": Date.tomorrow.to_s })
    end

    it "returns an error when completion date is more than 18 months ago" do
      assert_errors(
        [rule_under_test_error],
        { "Completion-Date": Date.today.prev_month(19).to_s },
      )
    end
  end

  context "INVALID_HEATING_FOR_SINGLE_METER" do
    let(:error) do
      {
        "code": "INVALID_HEATING_FOR_SINGLE_METER",
        "title":
          'If "Meter-Type" is equal to 2 then "SAP-Main-Heating-Code" must not be equal to 401, 402, 404, 408, 409, 421 or 422',
      }.freeze
    end

    it "Rejects single meter with invalid  heating code" do
      relevant_heating_codes = %w[401 402 404 408 409 421 422]

      relevant_heating_codes.each do |heating_code|
        assert_errors(
          [error],
          { "Meter-Type": "2", "SAP-Main-Heating-Code": heating_code },
        )
      end
    end
  end

  context "SUPPLY_ROOF_U_VALUE_OR_INSULATION_THICKNESS" do
    let(:error) do
      {
        "code": "SUPPLY_ROOF_U_VALUE_OR_INSULATION_THICKNESS",
        "title":
          'Only one of "Roof-Insulation-Thickness", "Rafter-Insulation-Thickness", "Flat-Roof-Insulation-Thickness", "Sloping-Ceiling-Insulation-Thickness" or "Roof-U-Value" may be supplied',
      }.freeze
    end

    it "Accepts assessment where only one value is supplied" do
      assert_errors([], {})
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
          [],
          { "SAP-Building-Part Roof-Insulation-Thickness": :delete },
          [
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
        [error],
        {},
        [
          {
            selector: "Roof-Insulation-Thickness",
            xml: "<Rafter-Insulation-Thickness>2</Rafter-Insulation-Thickness>",
          },
        ],
      )
    end

    it "Rejects assessment where roof and flat roof insulation are supplied" do
      assert_errors(
        [error],
        {},
        [
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
        [error],
        {},
        [
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
        [error],
        {},
        [
          {
            selector: "Roof-Insulation-Thickness",
            xml: "<Roof-U-Value>2</Roof-U-Value>",
          },
        ],
      )
    end

    it "Rejects assessment with more than 2 types of roof insulation" do
      assert_errors(
        [error],
        {},
        [
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

  context "SUPPLY_MULTIPLE_BUILDING_PARTS" do
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
        [],
        { "Roof-Room-Connected": "Y" },
        [{ selector: "SAP-Building-Part", xml: building_part_xml }],
      )
    end

    it "returns no errors when roof room connected is n and only building part supplied" do
      assert_errors([], { "Roof-Room-Connected": "N" })
    end

    it "returns error when roof room connected is y and only building part supplied" do
      assert_errors([error], { "Roof-Room-Connected": "Y" })
    end
  end

  context "INSPECTION_DATE_LATER_THAN_COMPLETION_DATE" do
    let(:error) do
      {
        "code": "INSPECTION_DATE_LATER_THAN_COMPLETION_DATE",
        "title":
          'The "Completion-Date" must be equal to or later than "Inspection-Date"',
      }.freeze
    end

    it "allows lodgement when the Completion-Date is after the Inspection-Date" do
      assert_errors([], {
        "Inspection-Date": Date.yesterday.to_s ,
        "Completion-Date": Date.today.to_s,
      })
    end

    it "allows lodgement when the Inspection-Date and the Completion-Date are equal" do
      assert_errors([], {
        "Inspection-Date": Date.today.to_s ,
        "Completion-Date": Date.today.to_s,
      })
    end

    it "throws an error when the Inspection-Date is later than the Completion-Date" do
      assert_errors([error], {
        "Inspection-Date": Date.today.to_s ,
        "Completion-Date": Date.yesterday.to_s,
      })
    end

  end

  context "COMPLETION_DATE_LATER_THAN_REGISTRATION_DATE" do
    let(:error) do
      {
        "code": "COMPLETION_DATE_LATER_THAN_REGISTRATION_DATE",
        "title":
          'The "Completion-Date" must be before or equal to the "Registration-Date"',
      }.freeze
      end

      it "allows lodgement when the Registration-Date is after the Completion-Date" do
        assert_errors([], {
          "Completion-Date": Date.yesterday.to_s,
          "Registration-Date": Date.today.to_s ,
        })
      end

      it "allows lodgement when the Completion-Date and the Registration-Date are equal" do
        assert_errors([], {
          "Completion-Date": Date.today.to_s ,
          "Registration-Date": Date.today.to_s,
        })
      end

      it "throws an error when the Completion-Date is later than the Registration-Date" do
        assert_errors([error], {
          "Completion-Date": Date.today.to_s,
          "Registration-Date": Date.yesterday.to_s
        })
      end

  end

  context "Both INSPECTION_DATE_LATER_THAN_COMPLETION_DATE and COMPLETION_DATE_LATER_THAN_REGISTRATION_DATE" do
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
      assert_errors([], {
        "Inspection-Date": Date.yesterday.prev_day.to_s,
        "Completion-Date": Date.yesterday.to_s,
        "Registration-Date": Date.today.to_s
      })
    end

    it "allows lodgement when all the dates are equal" do
      assert_errors([], {
        "Inspection-Date": Date.today.to_s,
        "Completion-Date": Date.today.to_s,
        "Registration-Date": Date.today.to_s
      })
    end

    it "throws the Inspection error when the Completion-Date is before the Inspection-Date" do
      assert_errors([inspection_date_error], {
        "Inspection-Date": Date.yesterday.to_s ,
        "Completion-Date": Date.yesterday.prev_day.to_s,
        "Registration-Date": Date.today.to_s
      })
    end

    it "throws the Completion error when the Registration-Date is before the Completion-Date" do
      assert_errors([completion_date_error], {
        "Inspection-Date": Date.yesterday.prev_day.to_s ,
        "Completion-Date": Date.today.to_s,
        "Registration-Date": Date.yesterday.to_s
      })
    end

    it "throws both errors when both the Inspection-Date is later than the Completion-Date and when the Completion-Date is later than the Registration-Date" do
      assert_errors([inspection_date_error, completion_date_error], {
        "Inspection-Date": Date.today.to_s,
        "Completion-Date": Date.yesterday.to_s,
        "Registration-Date": Date.yesterday.prev_day.to_s
      })
    end

    it "throws Completion error when the Registration-Date is before the Inspection- and Completion-Date" do
      assert_errors([completion_date_error], {
        "Inspection-Date": Date.yesterday.to_s ,
        "Completion-Date": Date.today.to_s,
        "Registration-Date": Date.yesterday.prev_day.to_s
      })
    end
  end
end
