describe Gateway::ExportNiGateway do
  include RSpecRegisterApiServiceMixin

  subject { described_class.new }

  context "when extracting Northern Ireland data for export " do
    before(:all) do
      Timecop.freeze(2021, 2, 22, 0, 0, 0)
    end

    after(:all) do
      Timecop.return
    end

    it "call the gateway without error" do
      expect { subject }.not_to raise_error
    end

    describe ".fetch_assessments" do
      before(:all) do
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
        expect(subject.fetch_assessments(%w[RdSAP SAP]).sort_by! { |k| k["assessment_id"] }).to eq(domestic_expectation)
      end

      it "exports only commercial certificates that have a BT postcode and a NI schema" do
        expect(subject.fetch_assessments("CEPC")).to eq(commercial_expectation)
      end

      context "when a certificate is opted out" do
        before do
          ActiveRecord::Base.connection.exec_query("UPDATE assessments SET opt_out = true WHERE assessment_id = '0000-0000-0000-0000-0002'")
        end

        let(:results) do
          subject.fetch_assessments(%w[RdSAP SAP]).sort_by! { |k| k["assessment_id"] }
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
          subject.fetch_assessments(%w[RdSAP SAP]).sort_by! { |k| k["assessment_id"] }
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
          subject.fetch_assessments(%w[RdSAP SAP]).sort_by! { |k| k["assessment_id"] }
        end

        let!(:commercial_results) do
          subject.fetch_assessments("CEPC")
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
    end
  end
end
