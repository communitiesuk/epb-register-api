describe UseCase::ExportOpenDataCommercial do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release" do
    describe "for the commercial certificates and reports" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:non_domestic_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }
      let(:non_domestic_assessment_id) { non_domestic_xml.at("//CEPC:RRN") }
      let(:non_domestic_assessment_date) do
        non_domestic_xml.at("//CEPC:Registration-Date")
      end
      let(:number_assessments_to_test) { 2 }

      # Lodge a dec to ensure it is not exported
      let(:domestic_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec") }
      let(:domestic_assessment_id) { domestic_xml.at("RRN") }
      let(:domestic_assessment_date) { domestic_xml.at("Registration-Date") }

      let(:exported_data) do
        described_class
          .new
          .execute(1, "2019-07-01")
          .sort_by! { |key| key[:rrn] }
      end

      let(:date_today) { DateTime.now.strftime("%F") }

      let(:statistics) do
        gateway = Gateway::OpenDataLogGateway.new
        gateway.get_statistics
      end

      expected_values = {
        rrn: "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
        address1: "Some Unit",
        address2: "2 Lonely Street",
        address3: "Some Area",
        address4: "Some County",
        posttown: "Whitbury",
        postcode: "A0 0AA",
        building_reference_number: "UPRN-000000000001",
        asset_rating: "80",
        asset_rating_band: "d",
        property_type: "B1 Offices and Workshop businesses",
        inspection_date: "2020-05-04",
        lodgement_date: "2020-05-04",
        transaction_type: "1",
        new_build_benchmark: "28",
        existing_stock_benchmark: "81",
        standard_emissions: "42.07",
        building_emissions: "67.09",
        main_heating_fuel: "Natural Gas",
        building_level: "3",
        floor_area: "403",
        other_fuel_description: "Test",
        special_energy_uses: "Test sp",
        aircon_present: "N",
        aircon_kw_rating: "100",
        estimated_aircon_kw_rating: "3",
        ac_inspection_commissioned: "1",
        target_emissions: "23.2",
        typical_emissions: "67.98",
        building_environment: "Air Conditioning",
        primary_energy: "413.22",
        report_type: "3",
      }

      let(:expected_values_index_1) do
        Samples.update_test_hash(
          expected_values,
          {
            rrn:
              "a6f818e3dd0ac70cbd2838cb0efe0b4aadf5b43ed33a6e7cd13cb9738dca5f60",
          },
        )
      end

      before(:all) do
        scheme_id = add_scheme_and_get_id
        non_domestic_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
        non_domestic_assessment_id = non_domestic_xml.at("//CEPC:RRN")
        non_domestic_assessment_date =
          non_domestic_xml.at("//CEPC:Registration-Date")
        non_domestic_assessment_postcode =
          non_domestic_xml.at("//CEPC:Postcode")

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

      it "returns the correct number of assessments in the CSV and the logs" do
        expect(exported_data.length).to eq(number_assessments_to_test)
        gateway = Gateway::OpenDataLogGateway.new
        expect(gateway.get_statistics[0]["num_rows"]).to eq(
          number_assessments_to_test,
        )
      end

      expected_values.keys.each do |index|
        it "returns the #{index} that matches the data for the 2nd row" do
          expect(exported_data[0][index.to_sym]).to eq(expected_values[index])
        end
      end

      expected_values.keys.each do |index|
        it "returns the #{index} that matches the data for the 2nd row" do
          expect(exported_data[1][index.to_sym]).to eq(
            expected_values_index_1[index],
          )
        end
      end
    end
  end

  context "when data has been exported more then once" do
    let(:exported_data) { described_class.new.execute(1, "2019-07-01") }
    let(:exported_data2) { described_class.new.execute(1, "2019-07-01") }

    it "should not return any data" do
      exported_data.length
      expect(exported_data2.length).to eq(0)
    end
  end
end
