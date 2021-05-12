describe UseCase::ExportOpenDataCommercial, set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release" do
    describe "for the commercial certificates and reports" do
      let(:export_object) { described_class.new }

      let(:exported_data) do
        described_class
          .new
          .execute("2019-07-01", 1)
          .sort_by! { |key| key[:assessment_id] }
      end

      let(:statistics) do
        gateway = Gateway::OpenDataLogGateway.new
        gateway.fetch_log_statistics
      end

      expected_values = {
        assessment_id:
          "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
        address1: "Some Unit",
        address2: "2 Lonely Street",
        address3: "Some Area",
        posttown: "Whitbury",
        postcode: "A0 0AA",
        building_reference_number: "UPRN-000000000001",
        asset_rating: "80",
        asset_rating_band: "d",
        property_type: "B1 Offices and Workshop businesses",
        inspection_date: "2020-05-04",
        lodgement_date: "2020-05-04",
        lodgement_datetime: "2021-02-18 00:00:00",
        transaction_type: "Mandatory issue (Marketed sale)",
        new_build_benchmark: "28",
        existing_stock_benchmark: "81",
        standard_emissions: "42.07",
        building_emissions: "67.09",
        main_heating_fuel: "Natural Gas",
        building_level: "3",
        floor_area: "403",
        other_fuel_desc: "Test",
        special_energy_uses: "Test sp",
        aircon_present: "N",
        aircon_kw_rating: "100",
        estimated_aircon_kw_rating: "3",
        ac_inspection_commissioned: "1",
        target_emissions: "23.2",
        typical_emissions: "67.98",
        building_environment: "Air Conditioning",
        primary_energy_value: "413.22",
        report_type: "3",
        renewable_sources: "Renewable sources test",
        region: "London",
      }

      let(:expected_values_index_1) do
        Samples.update_test_hash(
          expected_values,
          {
            assessment_id:
              "833db6da02dadee69b96c96917a5e190473828713f5074bd7d67a2371b315520",
            building_reference_number: nil,
            lodgement_datetime: datetime_today,
          },
        )
      end

      before(:all) do
        add_postcodes("A0 0AA", 51.5045, 0.0865, "London")
        add_outcodes("A0", 51.5045, 0.4865, "London")

        scheme_id = add_scheme_and_get_id
        non_domestic_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
        non_domestic_assessment_id = non_domestic_xml.at("//CEPC:RRN")
        non_domestic_assessment_date =
          non_domestic_xml.at("//CEPC:Registration-Date")
        non_domestic_assessment_postcode =
          non_domestic_xml.at("//CEPC:Postcode")
        non_domestic_building_reference_number =
          non_domestic_xml.at("//CEPC:UPRN")

        # Lodge a dec to ensure it is not exported
        domestic_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec")
        domestic_assessment_id = domestic_xml.at("RRN")
        domestic_assessment_date = domestic_xml.at("Registration-Date")

        add_assessor(
          scheme_id,
          "SPEC000000",
          AssessorStub.new.fetch_request_body(
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
            nonDomesticDec: "ACTIVE",
            domesticRdSap: "ACTIVE",
            domesticSap: "ACTIVE",
            nonDomesticSp3: "ACTIVE",
            nonDomesticCc4: "ACTIVE",
            gda: "ACTIVE",
          ),
        )

        non_domestic_assessment_date.children = "2020-05-04"
        lodge_assessment(
          assessment_body: non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        non_domestic_assessment_date.children = "2020-05-04"
        non_domestic_building_reference_number.children =
          "RRN-0000-0000-0000-0000-0008"
        non_domestic_assessment_id.children = "0000-0000-0000-0000-0328"
        lodge_assessment(
          assessment_body: non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        non_domestic_assessment_date.children = "2020-05-04"
        non_domestic_assessment_id.children = "0000-0000-0000-0000-0002"
        lodge_assessment(
          assessment_body: non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        # Date too early so not exported
        non_domestic_assessment_date.children = "2018-05-04"
        non_domestic_assessment_id.children = "0000-0000-0000-0000-0001"
        lodge_assessment(
          assessment_body: non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        # add lodgement for Northern Ireland not to be export
        non_domestic_assessment_postcode.children = "BT1 2DE"
        non_domestic_assessment_date.children = "2020-11-11"
        non_domestic_assessment_id.children = "0000-0000-0000-0000-0101"
        lodge_assessment(
          assessment_body: non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        # Domestic assessment not exported
        domestic_assessment_date.children = "2018-05-04"
        domestic_assessment_id.children = "0000-0000-0000-0000-0005"
        lodge_assessment(
          assessment_body: domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )
      end

      let(:rrn_assessment) do
        expected_data_hash =
          exported_data.select do |hash|
            hash[:assessment_id] ==
              "833db6da02dadee69b96c96917a5e190473828713f5074bd7d67a2371b315520"
          end
        expected_data_hash.first
      end

      it "returns the correct number of assessments in the CSV and the logs" do
        expect(exported_data.length).to eq(3)
        expect(statistics[0]["num_rows"]).to eq(3)
      end

      expected_values.reject { |k| %i[lodgement_datetime].include? k }.keys
        .each do |index|
        it "returns the #{index} that matches the data for the 1st row" do
          expect(exported_data[0][index.to_sym]).to eq(expected_values[index])
        end
      end

      expected_values.reject { |k| %i[lodgement_datetime].include? k }.keys
        .each do |index|
        it "returns the #{index} that matches the data for the 2nd row" do
          expect(exported_data[1][index.to_sym]).to eq(
            expected_values_index_1[index],
          )
        end
      end

      3.times do |i|
        it "expected valid assessment number #{i} lodged time to equal the frozen time" do
          expect(DateTime.parse(exported_data[i][:lodgement_datetime])).to eq(
            Time.now,
          )
        end
      end

      it "returns 3 rows when called with a different task_id" do
        expect(export_object.execute("2019-07-01", 1).length).to eq(3)
        expect(export_object.execute("2019-07-01", 2).length).to eq(3)
      end

      it "returns 3 rows when no task id is passed" do
        expect(export_object.execute("2019-07-01").length).to eq(3)
        expect(statistics.first["num_rows"]).to eq(3)
      end

      it "returns 0 rows if called with the existing task_id" do
        expect(export_object.execute("2019-07-01", 1).length).to eq(3)
        expect(export_object.execute("2019-07-01", 1).length).to eq(0)
      end

      it "returns a hash with building_reference_number nil when building_reference_number is not a UPRN" do
        expect(rrn_assessment[:building_reference_number]).to eq(nil)
      end
    end
  end
end
