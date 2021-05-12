describe UseCase::ExportOpenDataDec, set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release " do
    describe "for the DEC and reports" do
      let(:export_object) { described_class.new }

      expected_values = {
        assessment_id:
          "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
        building_reference_number: "UPRN-000000000001",
        address1: "Some Unit",
        address2: "2 Lonely Street",
        address3: "Some Area",
        posttown: "Whitbury",
        postcode: "A0 0AA",
        current_operational_rating: "1",
        yr1_operational_rating: "24",
        yr2_operational_rating: "40",
        operational_rating_band: "A",
        electric_co2: "7",
        heating_co2: "3",
        renewables_co2: "0",
        property_type: "B1 Offices and Workshop businesses",
        inspection_date: "2020-05-04",
        nominated_date: "2020-01-01",
        or_assessment_end_date: "2020-05-01",
        lodgement_date: "2020-05-04",
        lodgement_datetime: "2021-02-18 00:00:00",
        main_benchmark: "",
        main_heating_fuel: "Natural Gas",
        special_energy_uses: "special",
        renewable_sources: "1",
        total_floor_area: "99",
        occupancy_level: "level",
        typical_thermal_fuel_usage: "1",
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
        other_fuel: "other",
        estimated_aircon_kw_rating: "1",
      }

      let(:expected_values_1) do
        expected_values.merge(
          {
            assessment_id:
              "55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4",
            lodgement_datetime: datetime_today,
          },
        )
      end

      let(:expected_values_2) do
        expected_values.merge(
          {
            assessment_id:
              "5cb9fa3be789df637c7c20acac4e19c5ebf691f0f0d78f2a1b5f30c8b336bba6",
            building_reference_number: nil,
            lodgement_datetime: datetime_today,
          },
        )
      end

      let(:exported_data) do
        described_class
          .new
          .execute("2019-07-01", 3)
          .sort_by! { |key| key[:assessment_id] }
      end

      let(:statistics) do
        gateway = Gateway::OpenDataLogGateway.new
        gateway.fetch_log_statistics
      end

      let(:first_exported_dec) do
        exported_data.select do |hash|
          hash[:assessment_id] ==
            "5cb9fa3be789df637c7c20acac4e19c5ebf691f0f0d78f2a1b5f30c8b336bba6"
        end
      end

      before(:all) do
        scheme_id = add_scheme_and_get_id
        dec_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec")
        dec_assessment_id = dec_xml.at("RRN")
        dec_assessment_date = dec_xml.at("Registration-Date")
        dec_building_reference_number = dec_xml.at("UPRN")

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

        dec_assessment_id.children = "0000-0000-0000-0000-0004"
        dec_building_reference_number.children = "RRN-0000-0000-0000-0000-0004"
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
        expect(exported_data.length).to eq(3)
      end

      it "expects logs to have 2 rows after export" do
        exported_data
        expect(statistics[0]["num_rows"]).to eq(3)
      end

      expected_values.reject { |k| %i[lodgement_datetime].include? k }.keys
        .each do |index|
        it "returns the #{index} that matches the test data for the 1st row" do
          expect(exported_data[0][index.to_sym]).to eq(expected_values[index])
        end
      end

      expected_values.reject { |k| %i[lodgement_datetime].include? k }.keys
        .each do |index|
        it "returns the #{index} that matches the test data for the 2nd row" do
          expect(exported_data[1][index.to_sym]).to eq(expected_values_1[index])
        end
      end

      3.times do |i|
        it "returns assessment number #{i} to have lodged_datetime equal to frozen time" do
          expect(DateTime.parse(exported_data[i][:lodgement_datetime])).to eq(
            Time.now,
          )
        end
      end

      it "returns 2 rows when called with a different task_id" do
        expect(export_object.execute("2019-07-01", 1).length).to eq(3)
        expect(export_object.execute("2019-07-01", 2).length).to eq(3)
      end

      it "returns 2 rows no task id is passed" do
        expect(export_object.execute("2019-07-01").length).to eq(3)
        expect(statistics.first["num_rows"]).to eq(3)
      end

      it "returns 0 rows when called with the existing task_id" do
        expect(export_object.execute("2019-07-01", 1).length).to eq(3)
        expect(export_object.execute("2019-07-01", 1).length).to eq(0)
      end

      it "returns a hash with building_reference_number nil when building_reference_number is not a UPRN" do
        expect(first_exported_dec[0][:building_reference_number]).to eq(nil)
      end
    end
  end
end
