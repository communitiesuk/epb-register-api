# frozen_string_literal: true

describe "Acceptance::Reports::GetAssessmentRRNsBySchemeNameAndType" do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body nonDomesticNos3: "ACTIVE",
                                        nonDomesticDec: "ACTIVE",
                                        domesticRdSap: "ACTIVE",
                                        domesticSap: "ACTIVE",
                                        nonDomesticSp3: "ACTIVE"
  end

  let(:scheme_id) { add_scheme_and_get_id }

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }
  let(:valid_sap_xml) { Samples.xml "SAP-Schema-18.0.0" }
  let(:valid_cepc_xml) { Samples.xml "CEPC-8.0.0", "cepc" }
  let(:valid_cepc_rr_xml) { Samples.xml "CEPC-8.0.0", "cepc-rr" }
  let(:valid_cepc_and_cepc_rr_xml) { Samples.xml "CEPC-8.0.0", "cepc+rr" }
  let(:valid_dec_xml) { Samples.xml "CEPC-8.0.0", "dec" }
  let(:valid_dec_and_rr_xml) { Samples.xml "CEPC-8.0.0", "dec+rr" }
  let(:valid_dec_rr_xml) { Samples.xml "CEPC-8.0.0", "dec-rr" }
  let(:valid_ac_cert_xml) { Samples.xml "CEPC-8.0.0", "ac-cert" }
  let(:valid_ac_report_xml) { Samples.xml "CEPC-8.0.0", "ac-report" }
  let(:valid_ac_cert_and_ac_report_xml) do
    Samples.xml "CEPC-8.0.0", "ac-cert+ac-report"
  end

  let(:response) do
    get_assessment_report(
      start_date: Date.yesterday.strftime("%F"),
      end_date: Date.tomorrow.strftime("%F"),
      type: "scheme-and-type/rrn",
    ).body
  end

  context "when there are no lodgements" do
    it "returns an empty object if there are no lodgements in the time frame " do
      response =
        get_assessment_report(
          start_date: "2020-09-04",
          end_date: "2020-09-05",
          type: "scheme-and-type/rrn",
        ).body

      expect(JSON.parse(response, symbolize_names: true)).to eq(
        { data: "No lodgements during this time frame" },
      )
    end
  end

  context "when there are lodgements" do
    before do
      Timecop.freeze(2021, 6, 21, 10)

      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      doc = Nokogiri.XML valid_rdsap_xml
      doc.at("RRN").content = "0000-0000-0000-0000-0000"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-20.0.0",
      )

      doc = Nokogiri.XML valid_sap_xml
      doc.at("RRN").content = "0000-0000-0000-0000-0001"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "SAP-Schema-18.0.0",
      )

      doc = Nokogiri.XML valid_cepc_xml
      doc.at("//CEPC:RRN").content = "0000-0000-0000-0000-0002"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_cepc_rr_xml
      doc.at("//CEPC:RRN").content = "0000-0000-0000-0000-0009"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_cepc_and_cepc_rr_xml
      doc.xpath("//CEPC:RRN")[0].content = "0000-0000-0000-0000-3000"
      doc.xpath("//CEPC:RRN")[1].content = "0000-0000-0000-0000-3001"
      doc.xpath("//CEPC:Related-RRN")[0].content = "0000-0000-0000-0000-3001"
      doc.xpath("//CEPC:Related-RRN")[1].content = "0000-0000-0000-0000-3000"

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_dec_xml
      doc.at("RRN").content = "0000-0000-0000-0000-0003"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_dec_rr_xml
      doc.at("RRN").content = "0000-0000-0000-0000-0004"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_dec_and_rr_xml
      doc.css("RRN")[0].content = "0000-0000-0000-0000-1000"
      doc.css("RRN")[1].content = "0000-0000-0000-0000-1001"
      doc.css("Related-RRN")[0].content = "0000-0000-0000-0000-1001"
      doc.css("Related-RRN")[1].content = "0000-0000-0000-0000-1000"

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_ac_cert_xml
      doc.at("RRN").content = "0000-0000-0000-0000-0005"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_ac_report_xml
      doc.at("RRN").content = "0000-0000-0000-0000-0006"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_ac_cert_and_ac_report_xml
      doc.css("RRN")[0].content = "0000-0000-0000-0000-2000"
      doc.css("RRN")[1].content = "0000-0000-0000-0000-2001"
      doc.css("Related-RRN")[0].content = "0000-0000-0000-0000-2001"
      doc.css("Related-RRN")[1].content = "0000-0000-0000-0000-2000"

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      @second_scheme = add_scheme_and_get_id("test scheme two")

      add_assessor(@second_scheme, "SPEC000010", valid_assessor_request_body)

      doc = Nokogiri.XML valid_rdsap_xml
      doc.at("RRN").content = "1100-0000-0000-0000-0011"
      doc.at("Certificate-Number").content = "SPEC000010"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [@second_scheme],
        },
        schema_name: "RdSAP-Schema-20.0.0",
      )
    end

    after do
      Timecop.return
    end

    it "returns a report for a single scheme" do
      response =
        get_assessment_report(
          start_date: Date.yesterday.strftime("%F"),
          end_date: Date.tomorrow.strftime("%F"),
          scheme_id: @second_scheme,
          type: "scheme-and-type/rrn",
        ).body

      lodged_date = Date.today.strftime("%F")

      expect(
        response,
      ).to include "rrn,scheme_name,type_of_assessment,related_rrn,lodged_at"
      expect(
        response,
      ).to include "1100-0000-0000-0000-0011,test scheme two,RdSAP,,#{
                lodged_date
              }"
      expect(
        response,
      ).not_to include "0000-0000-0000-0000-0000,test scheme,RdSAP,,#{
                lodged_date
              }"
    end

    it "returns a report with the correct numbers of lodgements" do
      response =
        get_assessment_report(
          start_date: Date.yesterday.strftime("%F"),
          end_date: Date.tomorrow.strftime("%F"),
          type: "scheme-and-type/rrn",
        ).body

      lodged_date = Date.today.strftime("%F")

      expect(
        response,
      ).to include "rrn,scheme_name,type_of_assessment,related_rrn,lodged_at"
      expect(
        response,
      ).to include "0000-0000-0000-0000-0000,test scheme,RdSAP,,#{lodged_date}"
      expect(response).to include "0000-0000-0000-0000-0001,test scheme,SAP,,#{
                lodged_date
              }"
      expect(response).to include "0000-0000-0000-0000-0002,test scheme,CEPC,,#{
                lodged_date
              }"
      expect(
        response,
      ).to include "0000-0000-0000-0000-0009,test scheme,CEPC-RR,,#{
                lodged_date
              }"
      expect(
        response,
      ).to include "0000-0000-0000-0000-3001,test scheme,CEPC+RR,0000-0000-0000-0000-3000,#{
                lodged_date
              }"
      expect(response).to include "0000-0000-0000-0000-0003,test scheme,DEC,,#{
                lodged_date
              }"
      expect(
        response,
      ).to include "0000-0000-0000-0000-0004,test scheme,DEC-RR,,#{lodged_date}"
      expect(
        response,
      ).to include "0000-0000-0000-0000-1001,test scheme,DEC+RR,0000-0000-0000-0000-1000,#{
                lodged_date
              }"
      expect(
        response,
      ).to include "0000-0000-0000-0000-0005,test scheme,AC-CERT,,#{
                lodged_date
              }"
      expect(
        response,
      ).to include "0000-0000-0000-0000-0006,test scheme,AC-REPORT,,#{
                lodged_date
              }"
      expect(
        response,
      ).to include "0000-0000-0000-0000-2001,test scheme,AC-REPORT+CERT,0000-0000-0000-0000-2000,#{
                lodged_date
              }"
      expect(
        response,
      ).to include "1100-0000-0000-0000-0011,test scheme two,RdSAP,,#{
                lodged_date
              }"
    end

    context "when some lodgements are migrated" do
      it "does not include these in the report" do
        doc = Nokogiri.XML valid_rdsap_xml
        doc.at("RRN").content = "1111-0000-0000-0000-0001"

        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          scopes: %w[assessment:lodge migrate:assessment],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )

        expect(response).not_to include "1111-0000-0000-0000-0001"
      end
    end
  end

  context "when the start_date or end_date are not dates" do
    it "returns a validation error for the start_date" do
      response =
        get_assessment_report(
          start_date: "wrong-format",
          end_date: Date.tomorrow.strftime("%F"),
          type: "scheme-and-type/rrn",
          accepted_responses: [422],
        ).body

      expect(JSON.parse(response, symbolize_names: true)).to eq(
        {
          errors: [
            {
              code: "INVALID_REQUEST",
              title:
                "The property '#/startDate' Must be date in format YYYY-MM-DD",
            },
          ],
        },
      )
    end

    it "returns a validation error for the end_date" do
      response =
        get_assessment_report(
          start_date: Date.yesterday.strftime("%F"),
          end_date: "wrong-format",
          type: "scheme-and-type/rrn",
          accepted_responses: [422],
        ).body

      expect(JSON.parse(response, symbolize_names: true)).to eq(
        {
          errors: [
            {
              code: "INVALID_REQUEST",
              title:
                "The property '#/endDate' Must be date in format YYYY-MM-DD",
            },
          ],
        },
      )
    end
  end
end
