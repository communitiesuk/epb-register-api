describe UseCase::ExportOpenDataDec do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release " do
    describe "for the DEC and reports" do
      let(:date_today) { DateTime.now.strftime("%F") }
      let(:number_assessments_to_test) { 2 }

      let(:export_object) { described_class.new }

      expected_values = {
        rrn: "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
        building_reference_number: "UPRN-000000000001",
        address1: "Some Unit",
        address2: "2 Lonely Street",
        address3: "Some Area",
        posttown: "Whitbury",
        postcode: "A0 0AA",
        current_operational_rating: "1",
        yr1_operational_rating: "24",
        yr2_operational_rating: "40",
        energy_efficiency_band: "A",
        electric_co2: "7",
        heating_co2: "3",
        renewables_co2: "0",
        property_type: "B1 Offices and Workshop businesses",
        inspection_date: "2020-05-04",
        nominated_date: "2020-01-01",
        or_assessment_end_date: "2020-05-01",
        lodgement_date: "2020-05-04",
        main_benchmark: "",
        main_heating_fuel: "Natural Gas",
        special_energy_uses: "special",
        renewable_sources: "1",
        total_floor_area: "99",
        occupancy_level: "level",
        typical_thermal_use: "1",
        annual_electrical_fuel_usage: "1",
        typical_electrical_fuel_usage: "1",
        renewables_fuel_thermal: "1",
        renewables_electrical: "1",
        yr1_electricity_co2: "10",
        yr2_electricity_co2: "15",
        yr1_heating_co2: "5",
        yr2_heating_co2: "10",
        yr1_renewables_co2: "1",
        yr2_renewables_co2: "2",
        aircon_present: "Y",
        aircon_kw_rating: "1",
        ac_inspection_commissioned: "1",
        building_environment: "Heating and Natural Ventilation",
        building_category: "C1",
        report_type: "1",
      }

      let(:expected_values_1) do
        expected_values.merge(
          {
            rrn:
              "55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4",
          },
        )
      end

      let(:exported_data) do
        described_class
          .new
          .execute(3, "2019-07-01")
          .sort_by! { |key| key[:rrn] }
      end

      let(:statistics) do
        gateway = Gateway::OpenDataLogGateway.new
        gateway.get_log_statistics
      end

      before(:all) do
        scheme_id = add_scheme_and_get_id
        dec_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec")
        dec_assessment_id = dec_xml.at("RRN")
        dec_assessment_date = dec_xml.at("Registration-Date")

        # Lodge CEPC to ensure it is not exported
        non_domestic_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
        non_domestic_assessment_id = non_domestic_xml.at("//CEPC:RRN")

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

        lodge_assessment(
          assessment_body: dec_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        dec_assessment_id.children = "0000-0000-0000-0000-0001"
        lodge_assessment(
          assessment_body: dec_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        dec_assessment_id.children = "0000-0000-0000-0000-0002"
        dec_assessment_date.children = "2018-07-01"
        lodge_assessment(
          assessment_body: dec_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )

        non_domestic_assessment_id.children = "0000-0000-0000-0000-0003"
        lodge_assessment(
          assessment_body: non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-8.0.0",
        )
      end

      it "returns the correct number of assessments in the Data" do
        expect(exported_data.length).to eq(number_assessments_to_test)
      end

      it "expects logs to have 2 rows after export" do
        exported_data
        expect(statistics[0]["num_rows"]).to eq(2)
      end

      # 1st row to test
      # write at test for each key in test hash
      expected_values.keys.each do |index|
        it "returns the #{index} that matches the test data for the 1st row" do
          expect(exported_data[0][index.to_sym]).to eq(expected_values[index])
        end
      end

      # 2nd row to test
      # write at test for each key in test hash
      expected_values.keys.each do |index|
        it "returns the #{index} that matches the test data for the 2nd row" do
          expect(exported_data[1][index.to_sym]).to eq(expected_values_1[index])
        end
      end

      it "should return no rows if called with the existing task_id" do
        expect(export_object.execute(1, "2019-07-01").length).to eq(2)
        expect(export_object.execute(1, "2019-07-01").length).to eq(0)
      end

      it "should return 2 rows if called with a different task_id" do
        export = described_class.new
        expect(export_object.execute(1, "2019-07-01").length).to eq(2)
        expect(export_object.execute(2, "2019-07-01").length).to eq(2)
      end
    end
  end
end
