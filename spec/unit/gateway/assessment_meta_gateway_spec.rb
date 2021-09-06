describe Gateway::AssessmentMetaGateway do
  include RSpecRegisterApiServiceMixin
  context "when extracting meta data for an asesssment given a RRN " do
    subject(:gateway) { described_class.new }

    before do
      Timecop.freeze(2021, 6, 21, 12, 0, 0)

      scheme_id = add_scheme_and_get_id
      domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      domestic_rdsap_xml.at("UPRN").children = "RRN-0000-0000-0000-0000-0000"

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
      lodge_assessment(
        assessment_body: domestic_rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
      )

      ActiveRecord::Base.connection.exec_query("UPDATE assessments_address_id SET address_id='UPRN-000000000123'")
    end

    after do
      Timecop.return
    end

    let(:expected_data) do
      {
        assessment_address_id: "UPRN-000000000123",
        cancelled_at: nil,
        opt_out: false,
        not_for_issue_at: nil,
        type_of_assessment: "RdSAP",
        schema_type: "RdSAP-Schema-20.0.0",
        created_at: Time.now.utc,
      }
    end

    it "returns the expected data set" do
      expect(gateway.fetch("0000-0000-0000-0000-0000").symbolize_keys).to eq(expected_data)
    end

    it "returns no data if there is no assessment" do
      expect(gateway.fetch("0000-0000-0000-0000-0001")).to be_nil
    end

    context "when the certificate has been cancelled" do
      before do
        ActiveRecord::Base.connection.exec_query("UPDATE Assessments SET cancelled_at= '#{Time.now.utc}'")
      end

      it "returns the expected data set with the cancelled at date to be now" do
        expect(gateway.fetch("0000-0000-0000-0000-0000")["cancelled_at"]).to eq(Time.now)
      end
    end

    context "when the certificate has been opted_out" do
      before do
        ActiveRecord::Base.connection.exec_query("UPDATE assessments SET opt_out= true")
      end

      it "returns the expected data set with the cancelled at date to be now" do
        expect(gateway.fetch("0000-0000-0000-0000-0000")["opt_out"]).to eq(true)
      end
    end

    context "when the certificate has been marked as not for issue" do
      before do
        ActiveRecord::Base.connection.exec_query("UPDATE Assessments SET not_for_issue_at='#{Time.now.utc}'")
      end

      it "returns the expected data set with the cancelled at date to be now" do
        expect(gateway.fetch("0000-0000-0000-0000-0000")["not_for_issue_at"]).to eq(Time.now)
      end
    end
  end
end
