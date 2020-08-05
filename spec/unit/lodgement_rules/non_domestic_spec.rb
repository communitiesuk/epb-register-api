describe LodgementRules::NonDomestic do
  let(:xml_file) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
  end
  let(:xml_doc) do
    xml_doc = Nokogiri.XML(xml_file)

    xml_doc.at("//CEPC:Registration-Date").children = Date.yesterday.to_s

    xml_doc.at("//CEPC:Inspection-Date").children = Date.yesterday.to_s

    xml_doc.at("//CEPC:Issue-Date").children = Date.yesterday.to_s

    xml_doc.at("//CEPC:Effective-Date").children = Date.yesterday.to_s

    xml_doc.at("//CEPC:OR-Availability-Date").children = Date.yesterday.to_s

    xml_doc
  end

  def get_xml_errors(key, value)
    xml_doc.at(key).children = value

    wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, "CEPC-8.0.0")
    adapter = wrapper.get_view_model
    described_class.new.validate(adapter)
  end

  it "Returns an empty list for a valid file" do
    wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, "CEPC-8.0.0")
    adapter = wrapper.get_view_model
    errors = described_class.new.validate(adapter)
    expect(errors).to eq([])
  end

  context "DATES_CANT_BE_IN_FUTURE" do
    let(:error) do
      {
        "code": "DATES_CANT_BE_IN_FUTURE",
        "message":
          '"Inspection-Date", "Registration-Date" and "Issue-Date" must not be in the future',
      }.freeze
    end

    it "returns an error if the inspection date is in the future" do
      errors = get_xml_errors("//CEPC:Inspection-Date", Date.tomorrow.to_s)
      expect(errors).to include(error)
    end

    it "returns an error if the registration date is in the future" do
      errors = get_xml_errors("//CEPC:Registration-Date", Date.tomorrow.to_s)
      expect(errors).to include(error)
    end

    it "returns an error if the issue date is in the future" do
      errors = get_xml_errors("//CEPC:Effective-Date", Date.tomorrow.to_s)
      expect(errors).to include(error)
    end

    it "returns an error if the effective date is in the future" do
      errors = get_xml_errors("//CEPC:Issue-Date", Date.tomorrow.to_s)
      expect(errors).to include(error)
    end

    it "returns an error if the OR availability date is in the future" do
      errors = get_xml_errors("//CEPC:OR-Availability-Date", Date.tomorrow.to_s)
      expect(errors).to include(error)
    end

    it "returns an error if the OR assessment start date is in the future" do
      errors =
        get_xml_errors("//CEPC:OR-Assessment-Start-Date", Date.tomorrow.to_s)
      expect(errors).to include(error)
    end

    it "returns an error if the consumption type start date is in the future" do
      errors =
        get_xml_errors("//CEPC:Anthracite/CEPC:Start-Date", Date.tomorrow.to_s)
      expect(errors).to include(error)
    end
  end

  context "DATES_CANT_BE_MORE_THAN_4_YEARS_AGO" do
    let(:error) do
      {
        "code": "DATES_CANT_BE_MORE_THAN_4_YEARS_AGO",
        "message":
          '"Inspection-Date", "Registration-Date" and "Issue-Date" must not be more than 4 years ago',
      }.freeze
    end

    it "returns an error if the inspection date is more than four years ago" do
      four_years_and_a_day_ago = (Date.today << 12 * 4) - 1
      errors =
        get_xml_errors("//CEPC:Inspection-Date", four_years_and_a_day_ago.to_s)
      expect(errors).to include(error)
    end

    it "returns an error if the registration date is more than four years ago" do
      four_years_and_a_day_ago = (Date.today << 12 * 4) - 1
      errors =
        get_xml_errors(
          "//CEPC:Registration-Date",
          four_years_and_a_day_ago.to_s,
        )
      expect(errors).to include(error)
    end

    it "returns an error if the issue date is more than four years ago" do
      four_years_and_a_day_ago = (Date.today << 12 * 4) - 1
      errors =
        get_xml_errors("//CEPC:Issue-Date", four_years_and_a_day_ago.to_s)
      expect(errors).to include(error)
    end
  end

  context "FLOOR_AREA_CANT_BE_LESS_THAN_ZERO" do
    let(:error) do
      {
        "code": "FLOOR_AREA_CANT_BE_LESS_THAN_ZERO",
        "message":
          '"Floor-Area" must be greater than 0',
      }.freeze
    end

    it "returns an error if technical information / floor area is less than zero" do
      errors =
        get_xml_errors("//CEPC:Technical-Information/CEPC:Floor-Area", "-1")
      expect(errors).to include(error)
    end

    it "returns an error if multiple floor areas are less than zero" do
      xml_doc.at("//CEPC:Benchmark/CEPC:Floor-Area").children = '-1'

      errors =
          get_xml_errors("//CEPC:Technical-Information/CEPC:Floor-Area", "-1")
      expect(errors).to include(error)
    end
  end

  context "EMISSION_RATINGS_MUST_NOT_BE_NEGATIVE" do
    let(:error) do
      {
        "code": "EMISSION_RATINGS_MUST_NOT_BE_NEGATIVE",
        "message":
          '"SER", "BER", "TER" and "TYR" must not be negative numbers',
      }.freeze
    end

    it "returns an error if SER is minus one" do
      errors =
        get_xml_errors("//CEPC:SER", "-1.01")
      expect(errors).to include(error)
    end

    it "returns an error if BER is minus one" do
      errors =
        get_xml_errors("//CEPC:BER", "-1.01")
      expect(errors).to include(error)
    end

    it "returns an error if TER is minus one" do
      errors =
        get_xml_errors("//CEPC:TER", "-1.01")
      expect(errors).to include(error)
    end

    it "returns an error if TYR is minus one" do
      errors =
        get_xml_errors("//CEPC:TYR", "-1.01")
      expect(errors).to include(error)
    end

  end

end
