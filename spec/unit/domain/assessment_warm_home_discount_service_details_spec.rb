describe Domain::AssessmentWarmHomeDiscountServiceDetails do
  subject(:warm_home_discount_service_details) do
    described_class.new(**fields)
  end

  let(:fields) do
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
    }
  end

  it "represents the domain object as a hash" do
    expect(warm_home_discount_service_details.to_hash).to eq fields
  end
end
