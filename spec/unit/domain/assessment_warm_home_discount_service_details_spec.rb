describe Domain::AssessmentWarmHomeDiscountServiceDetails do
  subject(:warm_home_discount_service_details) do
    described_class.new(**arguments)
  end

  let(:arguments) do
    {
      address: {
        address_line1: "22 Acacia Avenue",
        address_line2: "Upper Wellgood",
        address_line3: "",
        address_line4: "",
        town: "Nether Wallop",
        postcode: "BS3 3FG",
      },
      lodgement_date: "2020-02-29",
      is_latest_assessment_for_address: true,
      property_type: "Mid-floor flat",
      built_form: "End-Terrace",
      property_age_band: "D",
      total_floor_area: 171.0,
      type_of_property: "House",
      address_id: "UPRN-001234567890",
    }
  end

  let(:expcted_hash) do
    {
      address: {
        address_line1: "22 Acacia Avenue",
        address_line2: "Upper Wellgood",
        address_line3: "",
        address_line4: "",
        town: "Nether Wallop",
        postcode: "BS3 3FG",
      },
      lodgement_date: "2020-02-29",
      is_latest_assessment_for_address: true,
      property_type: "Mid-floor flat",
      built_form: "End-Terrace",
      property_age_band: "D",
      total_floor_area: 171.0,
      type_of_property: "House",
      uprn: "001234567890",
    }
  end

  it "represents the domain object as a hash" do
    expect(warm_home_discount_service_details.to_hash).to eq expcted_hash
  end

  context "when the address id is an RRN" do
    it "the uprn is null" do
      arguments[:address_id] = "RRN-0000-1111-1234-1111-5555"
      expect(warm_home_discount_service_details.to_hash[:uprn]).to be_nil
    end
  end
end
