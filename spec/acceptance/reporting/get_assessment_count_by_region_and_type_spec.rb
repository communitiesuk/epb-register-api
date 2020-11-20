# frozen_string_literal: true

describe "Acceptance::Reports::GetAssessmentCountByRegionAndType" do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(
      nonDomesticNos3: "ACTIVE",
      nonDomesticDec: "ACTIVE",
      domesticRdSap: "ACTIVE",
      domesticSap: "ACTIVE",
      nonDomesticSp3: "ACTIVE",
    )
  end

  let(:scheme_id) { add_scheme_and_get_id }

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }
  let(:valid_sap_xml) { Samples.xml "SAP-Schema-18.0.0" }
  let(:valid_cepc_xml) { Samples.xml "CEPC-8.0.0", "cepc" }
  let(:valid_cepc_rr_xml) { Samples.xml "CEPC-8.0.0", "cepc-rr" }
  let(:valid_dec_xml) { Samples.xml "CEPC-8.0.0", "dec" }
  let(:valid_dec_rr_xml) { Samples.xml "CEPC-8.0.0", "dec-rr" }
  let(:valid_ac_cert_xml) { Samples.xml "CEPC-8.0.0", "ac-cert" }
  let(:valid_ac_report_xml) { Samples.xml "CEPC-8.0.0", "ac-report" }

  let(:response) do
    get_assessment_report(start_date: "2020-05-04", end_date: "2020-05-05").body
  end

  context "when getting a report on the number of lodged assessments" do
    before do
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)
    end

    before do
      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )
    end
    it "returns a CSV with headers and data included" do
      add_postcodes("A0 0AA", 51.5045, 0.0865, "London")

      expect(response).to eq(
        "number_of_assessments,type_of_assessment,region\n1,RdSAP,London\n",
      )
    end

    it "returns a region if there is a outcode match but not a postcode match" do
      add_postcodes("A0 0EK", 51.5045, 0.0865, "London")
      add_outcodes("A0", 51.5045, 0.4865, "Belfast")

      expect(response).to eq(
        "number_of_assessments,type_of_assessment,region\n1,RdSAP,Belfast\n",
      )
    end

    it "doesn't return a region if there is no outcode and no postcode match" do
      add_postcodes("NE 0AB", 51.5045, 0.0865, "London")
      add_outcodes("NE", 51.5045, 0.4865, "London")

      expect(response).to eq(
        "number_of_assessments,type_of_assessment,region\n1,RdSAP,\n",
      )
    end

    it "returns a region if there is not region for the postcode " do
      add_postcodes("A0 0AA", 51.5045, 0.0865)
      add_outcodes("A0", 51.5045, 0.4865, "London")

      expect(response).to eq(
        "number_of_assessments,type_of_assessment,region\n1,RdSAP,London\n",
      )
    end

    it "returns only assessments registered during the given time frame" do
      add_postcodes("A0 0AA", 51.5045, 0.0865, "London")

      doc = Nokogiri.XML valid_rdsap_xml
      doc.at("RRN").content = "0000-0000-0000-0000-0001"
      doc.at("Registration-Date").content = "2020-03-04"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      expect(response).to eq(
        "number_of_assessments,type_of_assessment,region\n1,RdSAP,London\n",
      )
    end

    it "returns an empty object if there are no lodgements in the time frame " do
      add_postcodes("A0 0AA", 51.5045, 0.0865, "London")

      response =
        get_assessment_report(start_date: "2020-09-04", end_date: "2020-09-05")
          .body

      expect(JSON.parse(response, symbolize_names: true)).to eq(
        { data: "No lodgements during this time frame" },
      )
    end

    it "lodgements are not returned if they have been cancelled" do
      add_postcodes("A0 0AA", 51.5045, 0.0865, "London")

      doc = Nokogiri.XML valid_rdsap_xml
      doc.at("Registration-Date").content = Date.today
      doc.at("RRN").content = "0000-0000-0000-0000-0001"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      update_assessment_status assessment_id: "0000-0000-0000-0000-0001",
                               assessment_status_body: {
                                 "status": "CANCELLED",
                               },
                               accepted_responses: [200],
                               auth_data: { scheme_ids: [scheme_id] }

      response =
        get_assessment_report(
          start_date: Date.yesterday, end_date: Date.tomorrow,
        ).body

      expect(JSON.parse(response, symbolize_names: true)).to eq(
        { data: "No lodgements during this time frame" },
      )
    end

    it "returns an array of different assessment types " do
      add_postcodes("A0 0AA", 51.5045, 0.0865, "London")

      doc = Nokogiri.XML valid_sap_xml
      doc.at("RRN").content = "0000-0000-0000-0000-0001"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "SAP-Schema-18.0.0",
      )

      doc = Nokogiri.XML valid_cepc_xml
      doc.at("//CEPC:RRN").content = "0000-0000-0000-0000-0002"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_cepc_rr_xml
      doc.at("//CEPC:RRN").content = "0000-0000-0000-0000-0009"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_dec_xml
      doc.at("RRN").content = "0000-0000-0000-0000-0003"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_dec_rr_xml
      doc.at("RRN").content = "0000-0000-0000-0000-0004"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_ac_cert_xml
      doc.at("RRN").content = "0000-0000-0000-0000-0005"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      doc = Nokogiri.XML valid_ac_report_xml
      doc.at("RRN").content = "0000-0000-0000-0000-0006"
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      response =
        get_assessment_report(start_date: "2020-05-04", end_date: "2020-06-20")
          .body

      expect(response).to eq <<~CSV
        number_of_assessments,type_of_assessment,region
        1,AC-CERT,London
        1,AC-REPORT,London
        1,CEPC,London
        1,CEPC-RR,London
        1,DEC,London
        1,DEC-RR,London
        1,RdSAP,London
        1,SAP,London
      CSV
    end
  end
end
