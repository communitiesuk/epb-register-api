describe "Gateway::AssessmentMetaGateway" do
  include RSpecRegisterApiServiceMixin
  context "when extracting meta data for an asesssment given a RRN " do
    subject { Gateway::AssessmentMetaGateway.new }

    before do
      Timecop.freeze(2021, 6, 21, 12, 0, 0)

      scheme_id = add_scheme_and_get_id
      domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      add_assessor(
        scheme_id,
        "SPEC000000",
        AssessorStub.new.fetch_request_body(
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
    end

    after do
      Timecop.return
    end

    let(:expcted_data) do
      {
        assessment_id: "0000-0000-0000-0000-0000",
        address_id: "UPRN-000000000000",
        cancelled_at: nil,
        opt_out: false,
        not_for_issue_at: nil,
        type_of_assessment: "RdSAP",
        schema_type: "RdSAP-Schema-20.0.0",
        created_at: Time.now.utc,
      }
    end

    it "returns the expected data set" do
      expect(subject.fetch("0000-0000-0000-0000-0000").symbolize_keys).to eq(expcted_data)
    end

    context "when the certificate has been cancelled" do
      before do
        ActiveRecord::Base.connection.exec_query("UPDATE Assessments SET cancelled_at= '#{Time.now.utc}'")
      end

      it "returns the expected data set with the cancelled at date to be now" do
        expect(subject.fetch("0000-0000-0000-0000-0000")["cancelled_at"]).to eq(Time.now)
      end
    end

    context "when the certificate has been opted_out" do
      before do
        ActiveRecord::Base.connection.exec_query("UPDATE Assessments SET opt_out= false")
      end

      it "returns the expected data set with the cancelled at date to be now" do
        expect(subject.fetch("0000-0000-0000-0000-0000")["opt_out"]).to eq(false)
      end
    end

    context "when the certificate has been marked as not for issue" do
      before do
        ActiveRecord::Base.connection.exec_query("UPDATE Assessments SET not_for_issue_at='#{Time.now.utc}'")
      end

      it "returns the expected data set with the cancelled at date to be now" do
        expect(subject.fetch("0000-0000-0000-0000-0000")["not_for_issue_at"]).to eq(Time.now)
      end
    end
  end
end
