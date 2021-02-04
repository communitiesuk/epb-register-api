describe UseCase::ExportOpenDataDec do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release " do
    describe "for the DEC and reports" do
      let(:date_today) { DateTime.now.strftime("%F") }
      let(:number_assessments_to_test) { 2 }
      expected_values = {
          rrn: "0000-0000-0000-0000-0000",
          building_reference_number: "UPRN-000000000001",
          address1: "Some Unit",
          address2: "2 Lonely Street",
          address3: "Some Area",
          posttown: "Post-Town1",
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
          { rrn: "0000-0000-0000-0000-0001" },
        )
      end

      let(:expected_values_minus_time) do
        expected_values.delete(:lodgement_datetime)
      end

      let(:exported_data) { described_class.new.execute }

      before(:all) do
        scheme_id = add_scheme_and_get_id
        dec_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec")
        dec_assessment_id = dec_xml.at("RRN")

        # Lodge CEPC to ensure it is not export
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

        # set exact time when data is lodged
        current_datetime = Time.now.strftime("%F %H:%M:%S")
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

        # in order to test the exact time of lodgement the time set on line 53
      end

      it "returns the correct number of assessments in the Data" do
        expect(exported_data.length).to eq(number_assessments_to_test)
      end

      # @TODO once tests have completed refactor to write one assertion for each row and compare to hash rather than for each column

      # it 'returns a row that matches the to_report hash' do
      #   expect(exported_data[0]).to eq(expected_values_minus_time)
      # end

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
    end
  end
end
