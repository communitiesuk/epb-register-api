describe LodgementRules::DomesticCommon do
  let(:docs_under_test) do
    [
      {
        xml_doc: Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0")),
        schema_name: "RdSAP-Schema-20.0.0",
      },
      {
        xml_doc: Nokogiri.XML(Samples.xml("RdSAP-Schema-NI-20.0.0")),
        schema_name: "RdSAP-Schema-NI-20.0.0",
      },
    ]
  end

  def assert_errors(key, value, expected_errors)
    docs_under_test.each do |doc|
      xml_doc = doc[:xml_doc]
      xml_doc.at(key).children = value

      wrapper =
        ViewModel::Factory.new.create(
          xml_doc.to_xml,
          "RdSAP-Schema-20.0.0",
          false,
        )
      adapter = wrapper.get_view_model
      errors = described_class.new.validate(adapter)
      expect(errors).to match_array(expected_errors)
    end
  end

  it "Returns an empty list for a valid file" do
    docs_under_test.each do |doc|
      wrapper =
        ViewModel::Factory.new.create(
          doc[:xml_doc].to_xml,
          doc[:schema_name],
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
      assert_errors("Habitable-Room-Count", "6.2", [error])
    end

    it "returns an error if the habitable room count is zero" do
      assert_errors("Habitable-Room-Count", "0", [error])
    end

    it "returns an error if the habitable room count is negative" do
      assert_errors("Habitable-Room-Count", "-2", [error])
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
      assert_errors("Energy-Rating-Current", "0", [error])
    end

    it "returns an error if Energy Rating Potential is 0" do
      assert_errors("Energy-Rating-Potential", "0", [error])
    end

    it "returns an error if Environmental-Impact-Current is 0" do
      assert_errors("Environmental-Impact-Current", "0", [error])
    end

    it "returns an error if Environmental-Impact-Potential is 0" do
      assert_errors("Environmental-Impact-Potential", "0", [error])
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
      assert_errors("Wall/Description", "wall", [error])
    end

    it "returns an error if Roof has a description of roof" do
      assert_errors("Roof/Description", "roof", [error])
    end

    it "returns an error if Floor has a description of floor" do
      assert_errors("Floor/Description", "floor", [error])
    end

    it "returns an error if Window has a description of window" do
      assert_errors("Window/Description", "window", [error])
    end

    it "returns an error if Main-Heating has a description of main-heating" do
      assert_errors("Main-Heating/Description", "main-heating", [error])
    end

    it "returns an error if Main-Heating-Controls has a description of main-heating-controls" do
      assert_errors(
        "Main-Heating-Controls/Description",
        "main-heating-controls",
        [error],
      )
    end

    it "returns an error if Hot-Water has a description of hot-water" do
      assert_errors("Hot-Water/Description", "hot-water", [error])
    end

    it "returns an error if Lighting has a description of lighting" do
      assert_errors("Lighting/Description", "lighting", [error])
    end

    it "returns an error if Secondary-Heating has a description of secondary-heating" do
      assert_errors(
        "Secondary-Heating/Description",
        "secondary-heating",
        [error],
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
      assert_errors("SAP-Floor-Dimension/Total-Floor-Area", "0", [error])
    end

    it "returns an error if the floor area is negative" do
      assert_errors("SAP-Floor-Dimension/Total-Floor-Area", "-6", [error])
    end

    it "returns an error if the floor area is more than 3000" do
      assert_errors("SAP-Floor-Dimension/Total-Floor-Area", "3001", [error])
    end
  end
end
