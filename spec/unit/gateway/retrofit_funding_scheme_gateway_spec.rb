describe Gateway::RetrofitFundingSchemeGateway, :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  let(:scheme_id) { add_scheme_and_get_id }

  let(:rdsap_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }

  let(:cepc_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }

  context "when expecting to find one assessment" do
    before do
      add_super_assessor(scheme_id:)

      lodge_assessment(
        assessment_body: rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )
    end

    context "when there is only a single assessment for a UPRN" do
      it "searches by uprn and finds the assessment id where one match exists" do
        result = gateway.find_by_uprn("000000000000")
        expect(result).to eq("0000-0000-0000-0000-0000")
      end
    end

    context "when there is more than one assessment for a UPRN" do
      let(:latest_rrn) { "0000-0000-0000-0000-0013" }

      before do
        superseded_rdsap = rdsap_xml.clone
        superseded_rdsap.at("RRN").children = latest_rrn
        superseded_rdsap.at("Registration-Date").children = "2015-05-04"

        lodge_assessment(
          assessment_body: superseded_rdsap.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )
      end

      it "searches by uprn and finds the assessment id of the most recent assessment" do
        result = gateway.find_by_uprn("000000000000")
        expect(result).to eq("0000-0000-0000-0000-0000")
      end
    end

    context "when there is a more recent cancelled assessment for a UPRN" do
      let(:latest_rrn) { "0000-0000-0000-0000-0013" }

      before do
        cancelled_rdsap = rdsap_xml.clone
        cancelled_rdsap.at("RRN").children = latest_rrn
        cancelled_rdsap.at("Registration-Date").children = "2021-05-04"

        lodge_assessment(
          assessment_body: cancelled_rdsap.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )

        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0013",
          assessment_status_body: {
            "status": "CANCELLED",
          },
          accepted_responses: [200],
          auth_data: {
            scheme_ids: [scheme_id],
          },
        )
      end

      it "searches by uprn and returns the assessment id of the most recent valid assessment" do
        result = gateway.find_by_uprn("000000000000")
        expect(result).to eq("0000-0000-0000-0000-0000")
      end
    end

    context "when there is a more recent not-for-issue assessment for a UPRN" do
      let(:latest_rrn) { "0000-0000-0000-0000-0013" }

      before do
        not_for_issue_rdsap = rdsap_xml.clone
        not_for_issue_rdsap.at("RRN").children = latest_rrn
        not_for_issue_rdsap.at("Registration-Date").children = "2021-05-04"

        lodge_assessment(
          assessment_body: not_for_issue_rdsap.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )

        update_assessment_status(
          assessment_id: "0000-0000-0000-0000-0013",
          assessment_status_body: {
            "status": "NOT_FOR_ISSUE",
          },
          accepted_responses: [200],
          auth_data: {
            scheme_ids: [scheme_id],
          },
        )
      end

      it "searches by uprn and returns the assessment id of the most recent for issue assessment" do
        result = gateway.find_by_uprn("000000000000")
        expect(result).to eq("0000-0000-0000-0000-0000")
      end
    end
  end

  context "when expecting to find no assessments" do
    context "when there is only a non domestic assessment for a UPRN" do
      before do
        add_super_assessor(scheme_id:)

        lodge_assessment(
          assessment_body: cepc_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-8.0.0",
        )
      end

      it "searches by uprn and returns nil" do
        result = gateway.find_by_uprn("000000000001")
        expect(result).to be_nil
      end
    end

    context "when there is only an opted-out assessment for a UPRN" do
      before do
        add_super_assessor(scheme_id:)

        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )

        opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")
      end

      it "searches by uprn and returns nil" do
        result = gateway.find_by_uprn("000000000000")
        expect(result).to be_nil
      end
    end

    context "when there are no assessments for a UPRN" do
      before do
        add_super_assessor(scheme_id:)

        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )
      end

      it "searches by uprn and returns nil" do
        result = gateway.find_by_uprn("000000000001")
        expect(result).to be_nil
      end
    end
  end
end
