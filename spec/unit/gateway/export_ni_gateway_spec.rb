describe Gateway::ExportNiGateway do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  let(:scheme_id) do
    add_scheme_and_get_id
  end

  before(:all) do
    Timecop.freeze(2021, 2, 22, 0, 0, 0)
  end

  after(:all) do
    Timecop.return
  end

  context "when extracting Northern Ireland data for export " do
    it "call the gateway without error" do
      expect { gateway }.not_to raise_error
    end

    describe ".fetch_assessments" do
      before do
        scheme_id = add_scheme_and_get_id
        add_super_assessor(scheme_id: scheme_id)

        domestic_ni_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-NI-18.0.0")

        domestic_ni_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-NI-20.0.0")
        domestic_ni_rdsap_assessment_id = domestic_ni_rdsap_xml.at("RRN")
        domestic_ni_rdsap_address_id = domestic_ni_rdsap_xml.at("UPRN")
        domestic_ni_rdsap_address_id.remove

        domestic_sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
        domestic_sap_assessment_id = domestic_sap_xml.at("RRN")

        lodge_assessment(
          assessment_body: domestic_ni_sap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-NI-18.0.0",
          override: true,
        )

        domestic_ni_rdsap_assessment_id.children = "0000-0000-0000-0000-0002"
        lodge_assessment(
          assessment_body: domestic_ni_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-NI-20.0.0",
          override: true,
        )

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

        non_domestic_xml = Nokogiri.XML Samples.xml("CEPC-NI-8.0.0", "cepc")
        non_domestic_assessment_id = non_domestic_xml.at("RRN")
        non_domestic_assessment_id.children = "9000-0000-0000-0000-1019"
        non_domestic_xml_postcode = non_domestic_xml.at("Postcode")
        non_domestic_xml_postcode.children = "BT5 2SA"

        lodge_assessment(
          assessment_body: non_domestic_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-NI-8.0.0",
        )

        non_domestic_xml_old = Nokogiri.XML Samples.xml("CEPC-7.1", "cepc")
        non_domestic_assessment_id = non_domestic_xml_old.at("RRN")
        non_domestic_assessment_id.children = "9000-0000-0000-0000-2110"
        non_domestic_xml_postcode = non_domestic_xml_old.at("Postcode")
        non_domestic_xml_postcode.children = "BT1 1SB"
        uprn = non_domestic_xml_old.at("UPRN")
        uprn.children = "000000000009"
        address_line_one = non_domestic_xml_old.at("Address-Line-1")
        address_line_one.children = "NI house"

        lodge_assessment(
          assessment_body: non_domestic_xml_old.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
          schema_name: "CEPC-7.1",
          migrated: true,
        )
      end

      let(:domestic_expectation) do
        [{ "assessment_id" => "0000-0000-0000-0000-0000",
           "lodgement_date" => "2020-05-04",
           "lodgement_datetime" => "2021-02-22 00:00:00",
           "uprn" => "UPRN-000000000000",
           "opt_out" => false,
           "cancelled" => false },
         { "assessment_id" => "0000-0000-0000-0000-0002",
           "lodgement_date" => "2020-05-04",
           "lodgement_datetime" => "2021-02-22 00:00:00",
           "uprn" => nil,
           "opt_out" => false,
           "cancelled" => false }]
      end

      let(:commercial_expectation) do
        [{ "assessment_id" => "9000-0000-0000-0000-1019",
           "lodgement_date" => "2020-05-04",
           "lodgement_datetime" => "2021-02-22 00:00:00",
           "uprn" => "UPRN-000000000001",
           "opt_out" => false,
           "cancelled" => false }]
      end

      it "exports only domestic certificates that have a BT postcode and a NI schema" do
        expect(gateway.fetch_assessments(type_of_assessment: %w[RdSAP SAP]).sort_by! { |k| k["assessment_id"] }).to eq(domestic_expectation)
      end

      it "exports commercial certificates that have a BT postcode and any CEPC schema" do
        cepc_7 = { "assessment_id" => "9000-0000-0000-0000-2110",
                   "lodgement_date" => "2020-05-04",
                   "lodgement_datetime" => "2021-02-22 00:00:00",
                   "uprn" => nil,
                   "opt_out" => false,
                   "cancelled" => false }
        commercial_expectation << cepc_7

        expect(gateway.fetch_assessments(type_of_assessment: %w[CEPC]).sort_by! { |k| k["assessment_id"] }).to eq(commercial_expectation)
      end

      context "when a certificate is opted out" do
        before do
          ActiveRecord::Base.connection.exec_query("UPDATE assessments SET opt_out = true WHERE assessment_id = '0000-0000-0000-0000-0002'")
        end

        let(:results) do
          gateway.fetch_assessments(type_of_assessment: %w[RdSAP SAP]).sort_by! { |k| k["assessment_id"] }
        end

        it "return false for the 1st row which was not opted out" do
          expect(results.first["opt_out"]).to eq(false)
        end

        it "return true for 2nd row which was opted out" do
          expect(results[1]["opt_out"]).to eq(true)
        end

        it "updates the opt_out value to false when it is null" do
          ActiveRecord::Base.connection.exec_query("UPDATE assessments SET opt_out = null WHERE assessment_id = '0000-0000-0000-0000-0002'")
          expect(results[1]["opt_out"]).to eq(false)
        end
      end

      context "when a certificate is cancelled" do
        before do
          ActiveRecord::Base.connection.exec_query("UPDATE assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0002'")
        end

        let(:results) do
          gateway.fetch_assessments(type_of_assessment: %w[RdSAP SAP]).sort_by! { |k| k["assessment_id"] }
        end

        it "return false for the 1st row which was not cancelled" do
          expect(results.first["cancelled"]).to eq(false)
        end

        it "return true for 2nd row which has been cancelled" do
          expect(results[1]["cancelled"]).to eq(true)
        end
      end

      context "when a certificate is not for issue" do
        before do
          ActiveRecord::Base.connection.exec_query("UPDATE assessments SET not_for_issue_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000'")
          ActiveRecord::Base.connection.exec_query("UPDATE assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0002'")
        end

        let!(:results) do
          gateway.fetch_assessments(type_of_assessment: %w[RdSAP SAP]).sort_by! { |k| k["assessment_id"] }
        end

        let!(:commercial_results) do
          gateway.fetch_assessments(type_of_assessment: %w[CEPC])
        end

        it "return true for the 1st row which was been opted out" do
          expect(results.first["cancelled"]).to eq(true)
        end

        it "return true for 2nd which was cancelled" do
          expect(results[1]["cancelled"]).to eq(true)
        end

        it "returns false for commercial certificate opt out " do
          expect(commercial_results.first["opt_out"]).to eq(false)
        end

        it "returns false for commercial certificate cancelled " do
          expect(commercial_results.first["cancelled"]).to eq(false)
        end
      end

      context "when filtering certificates by a date range" do
        before do
          ActiveRecord::Base.connection.exec_query("UPDATE Assessments SET date_registered = '2021-08-04 00:00:00' WHERE assessment_id= '0000-0000-0000-0000-0002'")
        end

        it "the export should only include the certificate lodged after  2021-08-01" do
          expect(gateway.fetch_assessments(type_of_assessment: %w[RdSAP SAP], date_from: "2021-08-01", date_to: "2021-08-28").length).to eq(1)
          expect(gateway.fetch_assessments(type_of_assessment: %w[RdSAP SAP], date_from: "2021-08-01", date_to: "2021-08-28").first["assessment_id"]).to eq("0000-0000-0000-0000-0002")
        end

        it "there are still a valid certificate to export when date does not include that lodged on 2021-08-01" do
          expect(gateway.fetch_assessments(type_of_assessment: %w[RdSAP SAP], date_from:  "1991-08-01", date_to: "2021-08-03").first["assessment_id"]).to eq("0000-0000-0000-0000-0000")
        end
      end
    end
  end

  context "when extracting Northern Ireland recommendations" do
    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id: scheme_id)

      cepc_rr_xml = Nokogiri.XML Samples.xml("CEPC-NI-8.0.0", "cepc+rr")
      cepc_rr_xml.xpath("//*[local-name() = 'RRN']").each_with_index do |node, index|
        node.content = "1111-0000-0000-0000-000#{index}"
      end

      cepc_rr_xml.xpath("//*[local-name() = 'Related-RRN']").reverse.each_with_index do |node, index|
        node.content = "1111-0000-0000-0000-000#{index}"
      end

      cepc_rr_xml.xpath("//*[local-name() = 'Postcode']").reverse_each { |node| node.content = "BT1 2TD" }
      cepc_rr_xml.xpath("//*[local-name() = 'UPRN']").reverse_each { |node| node.content = "UPRN-000000000001" }

      lodge_assessment(
        assessment_body: cepc_rr_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
        schema_name: "CEPC-NI-8.0.0",
        migrated: true,
      )
    end

    let(:commercial_rr_expectation) do
      [{ "assessment_id" => "1111-0000-0000-0000-0001",
         "lodgement_date" => "2020-05-04",
         "lodgement_datetime" => "2021-02-22 00:00:00",
         "uprn" => "UPRN-000000000001",
         "opt_out" => false,
         "cancelled" => false }]
    end

    it "exports only domestic certificates that have a BT postcode and a NI schema" do
      expect(gateway.fetch_assessments(type_of_assessment: %w[CEPC-RR]).sort_by! { |k| k["assessment_id"] }).to eq(commercial_rr_expectation)
    end
  end
end
