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
      let(:number_assments_to_test) {2}

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

        non_domestic_assessment_date.children = "2017-05-04"
        lodged = lodge_assessment(
          assessment_body: non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
            schema_name: "CEPC-8.0.0",
          )


        non_domestic_assessment_date.children = "2018-05-04"
        non_domestic_assessment_id.children = "0000-0000-0000-0000-0001"
        lodge_assessment(
          assessment_body: non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          override: true,
            schema_name: "CEPC-8.0.0",
          )


        open_data_export = described_class.new
        response =open_data_export.execute(
        {
          number_of_assessments: number_assments_to_test, max_runs: "3", batch: "3" },
        )
        @table = CSV.parse(response[0], headers:true)

      end

      it "returns the correct nubmer of assesments in the CSV" do
        expect(@table.length).to eq(number_assments_to_test)
      end


      it "returns the RRN in the CSV" do
        expect(@table["RRN"]).to eq(["0000-0000-0000-0000-0000", "0000-0000-0000-0000-0001"])
      end

      it "returns the ADDRESS1 in the CSV" do
        expect(@table["ADDRESS1"]).to eq(["2 Lonely Street", "2 Lonely Street"])
      end

      it "returns the ADDRESS2 in the CSV" do
        expect(@table["ADDRESS2"]).to eq([nil, nil])
      end

      it "returns the ADDRESS3 in the CSV" do
        expect(@table["ADDRESS3"]).to eq([nil, nil])
      end

      it "returns the POSTTOWN in the CSV" do
        expect(@table["POSTTOWN"]).to eq(["Post-Town1", "Post-Town1"])
      end

      it "returns the POSTCODE in the CSV" do
        expect(@table["POSTCODE"]).to eq(["A0 0AA", "A0 0AA"])
      end

      it "returns the BUILDING_REFERENCE_NUMBER in the CSV" do
        expect(@table["BUILDING_REFERENCE_NUMBER"]).to eq(["RRN-0000-0000-0000-0000-0000", "RRN-0000-0000-0000-0000-0001"])
      end

      it "returns the ASSET_RATING in the CSV" do
        expect(@table["ASSET_RATING"]).to eq(["80","80"])
      end

      it "returns the ASSET_RATING_BAND in the CSV" do
        expect(@table["ASSET_RATING_BAND"]).to eq(["d", "d"])
      end

      it "returns the PROPERTY_TYPE in the CSV" do
        expect(@table["PROPERTY_TYPE"]).to eq(["B1 Offices and Workshop businesses", "B1 Offices and Workshop businesses"])
      end

      it "returns the INSPECTION_DATE in the CSV" do
        expect(@table["INSPECTION_DATE"]).to eq(["2020-05-04", "2020-05-04"])
      end

      it "returns the LODGEMENT_DATE in the CSV" do
        expect(@table["LODGEMENT_DATE"]).to eq(["2017-05-04", "2018-05-04"])
      end

      it "returns the TRANSACTION_TYPE in the CSV" do
        expect(@table["TRANSACTION_TYPE"]).to eq(["1", "1"])
      end

      it "returns the NEW_BUILD_BENCHMARK in the CSV" do
        expect(@table["NEW_BUILD_BENCHMARK"]).to eq(["28", "28"])
      end

      it "returns the EXISTING_STOCK_BENCHMARK in the CSV" do
        expect(@table["EXISTING_STOCK_BENCHMARK"]).to eq(["81", "81"])
      end

      it "returns the BUILDING_LEVEL in the CSV" do
        expect(@table["BUILDING_LEVEL"]).to eq(["3", "3"])
      end

      it "returns the MAIN_HEATING_FUEL in the CSV" do
        expect(@table["MAIN_HEATING_FUEL"]).to eq(["Natural Gas", "Natural Gas"])
      end

       it "returns the OTHER_FUEL_DESC in the CSV" do
         expect(@table["OTHER_FUEL_DESC"]).to eq(["Test", "Test"])
      end

      it "returns the FLOOR_AREA in the CSV" do
        array = @table["FLOOR_AREA"].map{|string| string.to_i}
        expect(array).to eq([403, 403])
      end

      it "returns the STANDARD_EMISSIONS in the CSV" do
        array = @table["STANDARD_EMISSIONS"].map{|string| string.to_f}
        expect(array).to eq([67.09, 67.09])
      end

      it "returns the TARGET_EMISSIONS in the CSV" do
        array = @table["TARGET_EMISSIONS"].map{|string| string.to_f}
        expect(array).to eq([23.2, 23.2])
      end

       it "returns the TYPICAL_EMISSIONS in the CSV" do
         array = @table["TYPICAL_EMISSIONS"].map{|string| string.to_f}
         expect(array).to eq([67.98, 67.98])
       end

      it "returns the BUILDING_EMISSIONS in the CSV as floats" do
        array = @table["BUILDING_EMISSIONS"].map{|string| string.to_f}
        expect(array).to eq([67.09, 67.09])
      end

      it "returns the AIRCON_PRESENT in the CSV" do
        expect(@table["AIRCON_PRESENT"]).to eq(["N", "N"])
      end

      it "returns the BUILDING_ENVIRONMENT in the CSV" do
        expect(@table["BUILDING_ENVIRONMENT"]).to eq(["Air Conditioning", "Air Conditioning"])
      end

      it "returns the PRIMARY_ENERGY in the CSV as floats" do
        array = @table["PRIMARY_ENERGY"].map{|string| string.to_f}
        expect(array).to eq([413.22, 413.22])
      end

      it "returns the REPORT_TYPE in the CSV as integers" do
        array = @table["REPORT_TYPE"].map{|string| string.to_i}
        expect(array).to eq([3, 3])
      end

    end
    end
  end

