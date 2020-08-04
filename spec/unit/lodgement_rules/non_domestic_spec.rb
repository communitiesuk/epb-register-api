describe LodgementRules::NonDomestic do
  let(:xml_file) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
  end
  let(:xml_doc) do
    xml_doc = Nokogiri.XML(xml_file)

    xml_doc.at("//CEPC:Registration-Date").children = Date.yesterday.to_s

    xml_doc.at("//CEPC:Inspection-Date").children = Date.yesterday.to_s

    xml_doc.at("//CEPC:Issue-Date").children = Date.yesterday.to_s

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
      errors = get_xml_errors("//CEPC:Issue-Date", Date.tomorrow.to_s)
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
end
