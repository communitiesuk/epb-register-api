describe LodgementRules::NonDomestic, set_with_timecop: true do
  def assert_errors(key, value, expected_errors)
    docs_under_test.each do |doc|
      xml_doc = doc[:xml_doc]
      xml_doc.at(key).children = value

      wrapper =
        ViewModel::Factory.new.create(xml_doc.to_xml, doc[:schema_name], false)
      adapter = wrapper.get_view_model
      errors = described_class.new.validate(adapter)
      expect(errors).to match_array(expected_errors)
    end
  end

  context "when CEPC is lodged" do
    let!(:docs_under_test) do
      [
        {
          xml_doc:
            Nokogiri.XML(Samples.xml("CEPC-8.0.0", "cepc")).remove_namespaces!,
          schema_name: "CEPC-8.0.0",
        },
        {
          xml_doc:
            Nokogiri.XML(Samples.xml("CEPC-NI-8.0.0", "cepc")).remove_namespaces!,
          schema_name: "CEPC-NI-8.0.0",
        },
      ]
    end

    def reset_dates_to_yesterday(xml_doc)
      yesterday = Date.yesterday.to_s
      xml_doc.at("Registration-Date").children = yesterday
      xml_doc.at("Inspection-Date").children = yesterday
      xml_doc.at("Issue-Date").children = yesterday
      xml_doc.at("Effective-Date").children = yesterday
      xml_doc.at("OR-Availability-Date").children = yesterday
      xml_doc
    end

    it "Returns an empty list for a valid file" do
      docs_under_test.each do |doc|
        xml = doc[:xml_doc]
        xml_doc = reset_dates_to_yesterday(xml)
        wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, doc[:schema_name])
        adapter = wrapper.get_view_model
        errors = described_class.new.validate(adapter)
        expect(errors).to eq([])
      end
    end

    context "when dates for assessment are in the future" do
      let(:error) do
        {
          "code": "DATES_CANT_BE_IN_FUTURE",
          "title":
            'Inspection-Date", "Registration-Date", "Issue-Date", "Effective-Date", "OR-Availability-Date", "Start-Date" and "OR-Assessment-Start-Date" must not be in the future',
        }.freeze
      end

      it "returns an error if the inspection date is in the future" do
        assert_errors("Inspection-Date", Date.tomorrow.to_s, [error])
      end

      it "returns an error if the registration date is in the future" do
        assert_errors("Registration-Date", Date.tomorrow.to_s, [error])
      end

      it "returns an error if the issue date is in the future" do
        assert_errors("Effective-Date", Date.tomorrow.to_s, [error])
      end

      it "returns an error if the effective date is in the future" do
        assert_errors("Issue-Date", Date.tomorrow.to_s, [error])
      end

      it "returns an error if the OR availability date is in the future" do
        assert_errors("OR-Availability-Date", Date.tomorrow.to_s, [error])
      end

      it "returns an error if the OR assessment start date is in the future" do
        assert_errors("OR-Assessment-Start-Date", Date.tomorrow.to_s, [error])
      end

      it "returns an error if the consumption type start date is in the future" do
        assert_errors("Anthracite/Start-Date", Date.tomorrow.to_s, [error])
      end
    end

    context "when dates are from more than 4 years ago" do
      let(:error) do
        {
          "code": "DATES_CANT_BE_MORE_THAN_4_YEARS_AGO",
          "title":
            '"Inspection-Date", "Registration-Date" and "Issue-Date" must not be more than 4 years ago',
        }.freeze
      end

      it "returns an error if the inspection date is more than four years ago" do
        four_years_and_a_day_ago = (Date.today << 12 * 4) - 1
        assert_errors("Inspection-Date", four_years_and_a_day_ago.to_s, [error])
      end

      it "returns an error if the registration date is more than four years ago" do
        four_years_and_a_day_ago = (Date.today << 12 * 4) - 1
        assert_errors("Registration-Date", four_years_and_a_day_ago.to_s, [error])
      end

      it "returns an error if the issue date is more than four years ago" do
        four_years_and_a_day_ago = (Date.today << 12 * 4) - 1
        assert_errors("Issue-Date", four_years_and_a_day_ago.to_s, [error])
      end
    end

    context "when floor area is less than zero" do
      let(:error) do
        {
          "code": "FLOOR_AREA_CANT_BE_LESS_THAN_ZERO",
          "title": '"Floor-Area" must be greater than 0',
        }.freeze
      end

      it "returns an error if technical information / floor area is less than zero" do
        assert_errors("Technical-Information/Floor-Area", "-1", [error])
      end

      it "returns an error if technical information / floor area is zero" do
        assert_errors("Technical-Information/Floor-Area", "0", [error])
      end

      it "does not returns an error if technical information / floor area is just above 0" do
        assert_errors("Technical-Information/Floor-Area", "0.00001", [])
      end

      it "does not return an error if the floor area is not in the technical information section" do
        assert_errors("Benchmark/Floor-Area", "0", [])
      end
    end

    context "when emission ratings are negative" do
      let(:error) do
        {
          "code": "EMISSION_RATINGS_MUST_NOT_BE_NEGATIVE",
          "title": '"SER", "BER", "TER" and "TYR" must not be negative numbers',
        }.freeze
      end

      it "returns an error if SER is minus one" do
        assert_errors("SER", "-1.01", [error])
      end

      it "returns an error if BER is minus one" do
        assert_errors("BER", "-1.01", [error])
      end

      it "returns an error if TER is minus one" do
        assert_errors("TER", "-1.01", [error])
      end

      it "returns an error if TYR is minus one" do
        assert_errors("TYR", "-1.01", [error])
      end
    end

    context "when transaction type is 7" do
      let(:error) do
        {
          "code": "MUST_RECORD_TRANSACTION_TYPE",
          "title": '"Transaction-Type" must not be equal to 7',
        }.freeze
      end

      it "returns an error if Transaction-Type is 7" do
        assert_errors("Transaction-Type", "7", [error])
      end
    end

    context "when EPC related party disclosure is 13" do
      let(:error) do
        {
          "code": "MUST_RECORD_EPC_DISCLOSURE",
          "title": '"EPC-Related-Party-Disclosure" must not be equal to 13',
        }.freeze
      end

      it "returns an error if EPC-Related-Party-Disclosure is 13" do
        assert_errors("EPC-Related-Party-Disclosure", "13", [error])
      end
    end

    context "when energy type is 4" do
      let(:error) do
        {
          "code": "MUST_RECORD_ENERGY_TYPE",
          "title": '"Energy-Type" must not be equal to 4',
        }.freeze
      end

      it "returns an error if Energy-Type is 4" do
        assert_errors("Energy-Type", "4", [error])
      end
    end
  end

  context "when DEC is lodged" do
    let!(:docs_under_test) do
      [
        {
          xml_doc:
            Nokogiri.XML(Samples.xml("CEPC-8.0.0", "dec")).remove_namespaces!,
          schema_name: "CEPC-8.0.0",
        },
        {
          xml_doc:
            Nokogiri.XML(Samples.xml("CEPC-NI-8.0.0", "dec")).remove_namespaces!,
          schema_name: "CEPC-NI-8.0.0",
        },
      ]
    end

    it "returns an empty list for a valid file" do
      docs_under_test.each do |doc|
        xml_doc = doc[:xml_doc]
        wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, doc[:schema_name])
        adapter = wrapper.get_view_model
        errors = described_class.new.validate(adapter)
        expect(errors).to eq([])
      end
    end

    context "when reason type is 7" do
      let(:error) do
        {
          "code": "MUST_RECORD_REASON_TYPE",
          "title": '"Reason-Type" must not be equal to 7',
        }.freeze
      end

      it "returns an error if the reason type is 7" do
        assert_errors("Reason-Type", "7", [error])
      end
    end

    context "when DEC-Related-Party-Disclosure is 8" do
      let(:error) do
        {
          "code": "MUST_RECORD_DEC_DISCLOSURE",
          "title": '"DEC-Related-Party-Disclosure" must not be equal to 8',
        }.freeze
      end

      it "returns an error if the dec related party disclosure is 8" do
        assert_errors("DEC-Related-Party-Disclosure", "8", [error])
      end
    end

    context "when the nominated date is more than three months after the assessment end date" do
      let(:error) do
        {
          "code": "NOMINATED_DATE_TOO_LATE",
          "title":
            '"Nominated-Date" must not be more than three months after "OR-Assessment-End-Date"',
        }.freeze
      end

      it "returns an error if the nominated date is more than three months after the or-assessment-end-date" do
        assert_errors("OR-Assessment-End-Date", "2019-09-30", [error])
      end
    end


    context "when the DEC Status Code is 2" do
      let(:error) do
        {
          "code": "DEC_STATUS_INVALID",
          "title":
            'Asset rating only DECs with a "DEC-Status" of 2 are no longer valid',
        }.freeze
      end

      it "returns an error if the status code is for an invalid DEC type" do
        assert_errors("DEC-Status", "2", [error])
      end
    end
  end
end
