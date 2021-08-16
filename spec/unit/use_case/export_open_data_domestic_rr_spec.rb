describe UseCase::ExportOpenDataDomesticrr do
  include RSpecRegisterApiServiceMixin
  context "when creating the open data domestic recommendations report release" do
    describe "for the domestic recommendation report" do
      let(:export_object) { described_class.new }
      let(:grouped_results) do
        exported_data.group_by { |item| item[:assessment_id] }
      end
      let(:exported_data) do
        export_object
          .execute("2019-07-01")
          .sort_by! { |item| item[:assessment_id] }
      end
      let(:statistics) do
        gateway = Gateway::OpenDataLogGateway.new
        gateway.fetch_log_statistics
      end

      before(:all) do
        scheme_id = add_scheme_and_get_id
        domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        domestic_rdsap_assessment_id = domestic_rdsap_xml.at("RRN")
        domestic_rdsap_assessment_date =
          domestic_rdsap_xml.at("Registration-Date")

        domestic_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
        domestic_sap_assessment_id = domestic_sap_xml.at("RRN")
        domestic_sap_assessment_date = domestic_sap_xml.at("Registration-Date")

        domestic_legacy_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-17.0")
        domestic_legacy_sap_assessment_id = domestic_legacy_sap_xml.at("RRN")
        domestic_legacy_sap_assessment_date =
          domestic_legacy_sap_xml.at("Registration-Date")

        domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")
        domestic_ni_sap_assessment_id = domestic_ni_sap_xml.at("RRN")
        domestic_ni_sap_assessment_date =
          domestic_ni_sap_xml.at("Registration-Date")

        add_assessor(
          scheme_id: scheme_id,
          assessor_id: "SPEC000000",
          body: AssessorStub.new.fetch_request_body(
            non_domestic_nos3: "ACTIVE",
            non_domestic_nos4: "ACTIVE",
            non_domestic_nos5: "ACTIVE",
            non_domestic_dec: "ACTIVE",
            domestic_rd_sap: "ACTIVE",
            domestic_sap: "ACTIVE",
            non_domestic_sp3: "ACTIVE",
            non_domestic_cc4: "ACTIVE",
            gda: "ACTIVE",
          ),
        )

        domestic_rdsap_assessment_date.children = date_today
        domestic_rdsap_assessment_id.children = "0000-0000-0000-0000-0100"
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )

        domestic_legacy_sap_assessment_date.children = "2018-05-02"
        domestic_legacy_sap_assessment_id.children = "0000-0000-0000-0000-1010"
        lodge_assessment(
          assessment_body: domestic_legacy_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-17.0",
          override: true,
        )

        domestic_sap_assessment_date.children = date_today
        domestic_sap_assessment_id.children = "1000-0000-0000-0000-1010"
        lodge_assessment(
          assessment_body: domestic_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-18.0.0",
          override: true,
        )

        domestic_ni_sap_assessment_date.children = date_today
        domestic_ni_sap_assessment_id.children = "2000-0000-0000-0000-1010"
        lodge_assessment(
          assessment_body: domestic_ni_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-NI-18.0.0",
          override: true,
        )
      end

      it "returns the correct number of assessments excluding the NI lodgements and any before the given date" do
        expect(exported_data.length).to eq(5)
      end

      it "returns the correct number of recommendations for each assessment when grouped" do
        expect(grouped_results.length).to eq(2)
        # expect(exported_data.group_by{|item| item[:assessment_id]}[0].length).to eq(2)
      end

      it "returns recommendations in the following format" do
        expect(exported_data[0]).to eq(
          {
            assessment_id:
              "2da345c51a134b04e2c2a27d6ad48441cddebeba199d11a3a3ff8572ff75d9c8",
            improvement_descr_text: nil,
            improvement_summary_text: nil,
            indicative_cost: "£100 - £350",
            improvement_id: "5",
            improvement_item: 1,
          },
        )
        expect(exported_data[1]).to eq(
          {
            assessment_id:
              "2da345c51a134b04e2c2a27d6ad48441cddebeba199d11a3a3ff8572ff75d9c8",
            improvement_descr_text: "Improvement desc",
            improvement_summary_text: nil,
            indicative_cost: "2000",
            improvement_id: nil,
            improvement_item: 2,
          },
        )

        expect(exported_data[2]).to eq(
          {
            assessment_id:
              "9ef56d3e0ad9e5e8787715e05fdf61a2a85c7b7eb091827910c3d048ce2aee94",
            improvement_descr_text: nil,
            improvement_summary_text: nil,
            indicative_cost: "£100 - £350",
            improvement_id: "5",
            improvement_item: 1,
          },
        )

        expect(exported_data[3]).to eq(
          {
            assessment_id:
              "9ef56d3e0ad9e5e8787715e05fdf61a2a85c7b7eb091827910c3d048ce2aee94",
            improvement_descr_text: nil,
            improvement_summary_text: nil,
            indicative_cost: "2000",
            improvement_id: "1",
            improvement_item: 2,
          },
        )

        expect(exported_data[4]).to eq(
          {
            assessment_id:
              "9ef56d3e0ad9e5e8787715e05fdf61a2a85c7b7eb091827910c3d048ce2aee94",
            improvement_descr_text: "Improvement desc",
            improvement_summary_text: nil,
            indicative_cost: "1000",
            improvement_id: nil,
            improvement_item: 3,
          },
        )
      end

      it "returns 1 rows when called with a different task_id" do
        expect(export_object.execute("2019-07-01", 1).length).to eq(5)
        expect(export_object.execute("2019-07-01", 2).length).to eq(5)
      end

      it "returns 1 row when no task id is passed" do
        expect(export_object.execute("2019-07-01").length).to eq(5)
        expect(statistics.first["num_rows"]).to eq(2)
      end

      it "returns 0 rows when called with the existing task_id" do
        expect(export_object.execute("2019-07-01", 1).length).to eq(5)
        expect(export_object.execute("2019-07-01", 1).length).to eq(0)
      end
    end
  end
end
