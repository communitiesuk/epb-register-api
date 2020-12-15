describe UseCase::OpenDataExport do
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

      let(:non_domestic_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }
      let(:non_domestic_assessment_id) { non_domestic_xml.at("//CEPC:RRN") }
      let(:non_domestic_assessment_date) do
        non_domestic_xml.at("//CEPC:Registration-Date")
      end

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
        lodge_assessment(
          assessment_body: domestic_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "SAP-Schema-18.0.0",
          override: true,
        )

        open_data_export = described_class.new
        response =
          open_data_export.execute(
            { number_of_assessments: "3", max_runs: "3", batch: "3" },
            )
        @table = CSV.parse(response[0], headers:true)

      end

      it "returns the REPORT TYPE in the CSV" do
        expect(@table.by_col[0]).to eq(["RdSAP", "RdSAP", "SAP"])
      end

      it "returns the RRN in the CSV" do
        expect(@table.by_col[1]).to eq(["0000-0000-0000-0000-0000", "0000-0000-0000-0000-0001", "0000-0000-0000-0000-0003"])
      end

      it "returns the INSPECTION_DATE in the CSV" do
        expect(@table.by_col[2]).to eq(["2020-05-04", "2020-05-04", "2020-05-04"])
      end

      it "returns the LODGEMENT_DATE in the CSV" do
        expect(@table.by_col[3]).to eq(["2017-05-04", "2018-05-04", "2020-05-04"])
      end

      it "returns the LODGEMENT_DATE in the CSV" do
        expect(@table.by_col[3]).to eq(["2017-05-04", "2018-05-04", "2020-05-04"])
      end

      it "returns the BUILDING_REFERENCE_NUMBER in the CSV" do
        expect(@table.by_col[4]).to eq(["RRN-0000-0000-0000-0000-0000", "RRN-0000-0000-0000-0000-0001", "RRN-0000-0000-0000-0000-0003"])
      end

      it "returns the ADDRESS1 in the CSV" do
        expect(@table.by_col[5]).to eq( ["1 Some Street", "1 Some Street", "1 Some Street"])
      end

      it "returns the ADDRESS2 in the CSV" do
        expect(@table.by_col[6]).to eq(["", "", ""])
      end

      it "returns the ADDRESS3 in the CSV" do
        expect(@table.by_col[7]).to eq(["", "", ""])
      end

      it "returns the ADDRESS4 in the CSV" do
        expect(@table.by_col[8]).to eq(["", "", ""])
      end

      it "returns the POSTTOWN in the CSV" do
        expect(@table.by_col[9]).to eq(["Post-Town1", "Post-Town1", "Post-Town1"])
      end

      it "returns the POSTCODE in the CSV" do
        expect(@table.by_col[10]).to eq(["A0 0AA", "A0 0AA", "A0 0AA"])
      end

      it "returns the CURRENT_ENERGY_EFFICIENCY in the CSV" do
        expect(@table.by_col[11]).to eq(["50", "50", "50"])
      end

      it "returns the CURRENT_ENERGY_RATING in the CSV" do
        expect(@table.by_col[12]).to eq(["e", "e", "e"])
      end

      it "returns the POTENTIAL_ENERGY_EFFICIENCY in the CSV" do
        expect(@table.by_col[13]).to eq(["50", "50", "50"])
      end
    end
  end
end
