describe UseCase::ExportOpenDataDomestic do
  include RSpecRegisterApiServiceMixin

  context "when creating the open data reporting release" do
    describe "for the domestic certificates and reports" do
      let(:scheme_id) { add_scheme_and_get_id }

      let(:domestic_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }
      let(:domestic_assessment_id) { domestic_xml.at("RRN") }
      let(:domestic_assessment_date) { domestic_xml.at("Registration-Date") }

      let(:domestic_sap_xml) { Nokogiri.XML Samples.xml("SAP-Schema-18.0.0") }
      let(:domestic_sap_assessment_id) { domestic_sap_xml.at("RRN") }
      let(:domestic_sap_assessment_date) { domestic_sap_xml.at("Registration-Date") }
      let(:domestic_sap_assessment_level) { domestic_sap_xml.at("Level") }

      before do
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
        domestic_assessment_date.children = "2017-05-04"
        lodge_assessment(
          assessment_body: domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
        )

        domestic_assessment_date.children = "2018-05-04"
        domestic_assessment_id.children = "0000-0000-0000-0000-0001"
        lodge_assessment(
          assessment_body: domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
        )

        domestic_sap_assessment_date.children = "2020-05-04"
        domestic_sap_assessment_id.children = "0000-0000-0000-0000-0003"
        domestic_sap_assessment_level.children = "3"
        lodge_assessment(
          assessment_body: domestic_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "SAP-Schema-18.0.0",
          override: true,
        )

        open_data_export = described_class.new
        response =open_data_export.execute(
            { number_of_assessments: "3", max_runs: "3", batch: "3" },
            )
        @table = CSV.parse(response[0], headers:true)



      end

      it "returns the REPORT TYPE in the CSV" do
        expect(@table.by_col["REPORT_TYPE"]).to eq(["RdSAP", "RdSAP", "SAP"])
      end

      it "returns the RRN in the CSV" do
        expect(@table.by_col["RRN"]).to eq(["0000-0000-0000-0000-0000", "0000-0000-0000-0000-0001", "0000-0000-0000-0000-0003"])
      end

      it "returns the INSPECTION_DATE in the CSV" do
        expect(@table.by_col["INSPECTION_DATE"]).to eq(["2020-05-04", "2020-05-04", "2020-05-04"])
      end

      it "returns the LODGEMENT_DATE in the CSV" do
        expect(@table.by_col["LODGEMENT_DATE"]).to eq(["2017-05-04", "2018-05-04", "2020-05-04"])
      end

      it "returns the BUILDING_REFERENCE_NUMBER in the CSV" do
        expect(@table.by_col["BUILDING_REFERENCE_NUMBER"]).to eq(["RRN-0000-0000-0000-0000-0000", "RRN-0000-0000-0000-0000-0001", "RRN-0000-0000-0000-0000-0003"])
      end

      it "returns the ADDRESS1 in the CSV" do
        expect(@table.by_col["ADDRESS1"]).to eq( ["1 Some Street", "1 Some Street", "1 Some Street"])
      end

      it "returns the ADDRESS2 in the CSV" do
        expect(@table.by_col["ADDRESS2"]).to eq(["", "", ""])
      end

      it "returns the ADDRESS3 in the CSV" do
        expect(@table.by_col["ADDRESS3"]).to eq(["", "", ""])
      end

      it "returns the ADDRESS4 in the CSV" do
        expect(@table.by_col["ADDRESS4"]).to eq(["", "", ""])
      end

      it "returns the POSTTOWN in the CSV" do
        expect(@table.by_col["POSTTOWN"]).to eq(["Post-Town1", "Post-Town1", "Post-Town1"])
      end

      it "returns the POSTCODE in the CSV" do
        expect(@table.by_col["POSTCODE"]).to eq(["A0 0AA", "A0 0AA", "A0 0AA"])
      end

      it "returns the CURRENT_ENERGY_EFFICIENCY in the CSV" do
        expect(@table.by_col["CURRENT_ENERGY_EFFICIENCY"]).to eq(["50", "50", "50"])
      end

      it "returns the CURRENT_ENERGY_RATING in the CSV" do
        expect(@table.by_col["CURRENT_ENERGY_RATING"]).to eq(["e", "e", "e"])
      end

      it "returns the POTENTIAL_ENERGY_EFFICIENCY in the CSV" do
        expect(@table.by_col["POTENTIAL_ENERGY_EFFICIENCY"]).to eq(["50", "50", "50"])
      end

      it "returns the POTENTIAL_ENERGY_RATING in the CSV" do
        expect(@table.by_col["POTENTIAL_ENERGY_RATING"]).to eq(["e", "e", "e"])
      end

      it "returns the CONSTRUCTION_AGE_BAND in the CSV" do
        expect(@table.by_col["CONSTRUCTION_AGE_BAND"]).to eq(["K", "K", "1750"])
      end

      it "returns the PROPERTY_TYPE in the CSV" do
        expect(@table.by_col["PROPERTY_TYPE"]).to eq(["Dwelling-Type0", "Dwelling-Type0", "Dwelling-Type0"])
      end

      it "returns the TENURE in the CSV" do
        expect(@table.by_col["TENURE"]).to eq(["1", "1", "1"])
      end

      it "returns the ENERGY_CONSUMPTION_CURRENTin the CSV" do
        expect(@table.by_col["ENERGY_CONSUMPTION_CURRENT"]).to eq(["0", "0", "0"])
      end

      it "returns the CO2_EMISSIONS_CURRENT in the CSV" do
        expect(@table.by_col["CO2_EMISSIONS_CURRENT"]).to eq(["2.4", "2.4", "2.4"])
      end

      it "returns the LIGHTING_COST_CURRENT in the CSV" do
        expect(@table.by_col["LIGHTING_COST_CURRENT"]).to eq(["123.45", "123.45", "123.45"])
      end

      it "returns the LIGHTING_COST_POTENTIAL in the CSV" do
        expect(@table.by_col["LIGHTING_COST_POTENTIAL"]).to eq(["84.23", "84.23", "84.23"])
      end

      it "returns the HEATING_COST_CURRENT in the CSV" do
        expect(@table.by_col["HEATING_COST_CURRENT"]).to eq(["365.98", "365.98", "365.98"])
      end

      it "returns the HEATING_COST_POTENTIAL in the CSV" do
        expect(@table.by_col["HEATING_COST_POTENTIAL"]).to eq(["250.34", "250.34", "250.34"])
      end

      it "returns the HOT_WATER_COST_CURRENT in the CSV" do
        expect(@table.by_col["HOT_WATER_COST_CURRENT"]).to eq(["200.40", "200.40", "200.40"])
      end

      it "returns the HOT_WATER_COST_POTENTIAL in the CSV" do
        expect(@table.by_col["HOT_WATER_COST_POTENTIAL"]).to eq(["180.43", "180.43", "180.43"])
      end

      it "returns the TOTAL_FLOOR_AREA in the CSV" do
        expect(@table.by_col["TOTAL_FLOOR_AREA"]).to eq(["1.0", "1.0", "10.0"])
      end

      it "returns the MAIN_FUEL in the CSV" do
        expect(@table.by_col["MAIN_FUEL"]).to eq(["26", "26", "36"])
      end

      it "returns the TRANSACTION_TYPE in the CSV" do
        expect(@table.by_col["TRANSACTION_TYPE"]).to eq(["1", "1", "1"])
      end

      it "returns the ENVIRONMENT_IMPACT_CURRENT in the CSV" do
        expect(@table.by_col["ENVIRONMENT_IMPACT_CURRENT"]).to eq(["50", "50", "50"])
      end

      it "returns the ENVIRONMENT_IMPACT_POTENTIAL in the CSV" do
        expect(@table.by_col["ENVIRONMENT_IMPACT_POTENTIAL"]).to eq(["50", "50", "50"])
      end

      it "returns the ENERGY_CONSUMPTION_POTENTIAL in the CSV" do
        expect(@table.by_col["ENERGY_CONSUMPTION_POTENTIAL"]).to eq(["0", "0", "0"])
      end

      it "returns the CO2_EMISS_CURR_PER_FLOOR_AREA in the CSV" do
        expect(@table.by_col["CO2_EMISS_CURR_PER_FLOOR_AREA"]).to eq(["0", "0", "0"])
      end

      it "returns the MAINS_GAS_FLAG in the CSV" do
        expect(@table.by_col["MAINS_GAS_FLAG"]).to eq(["Y", "Y", nil])
      end

      it "returns the LEVEL in the CSV" do
        expect(@table.by_col["LEVEL"]).to eq(["1", "1", "3"])
      end

      it "returns the FLAT_TOP_STOREY in the CSV" do
        expect(@table.by_col["FLAT_TOP_STOREY"]).to eq(["N", "N", "Y"])
      end
    end
  end
end
