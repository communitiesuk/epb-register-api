# frozen_string_literal: true

describe "Acceptance::Reports::GetAssessmentCountByRegionAndType" do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(
      non_domestic_nos3: "ACTIVE",
      non_domestic_dec: "ACTIVE",
      domestic_rd_sap: "ACTIVE",
      domestic_sap: "ACTIVE",
      non_domestic_sp3: "ACTIVE",
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
    get_assessment_report(start_date: "2020-08-01", end_date: "2020-08-02").body
  end

  context "when getting a report on the number of lodged assessments" do
    before do
      add_assessor(scheme_id: scheme_id, assessor_id: "SPEC000000", body: valid_assessor_request_body)

      lodge_assessment_with_rrn(
        valid_rdsap_xml,
        "0000-0000-0000-0000-0000",
        "RdSAP-Schema-20.0.0",
        scheme_id,
        Time.utc(2020, 8, 1),
      )
    end

    after { Timecop.return }

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

      # Registers an assessment a day before the report time frame
      Timecop.freeze(Time.utc(2020, 5, 4))
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
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
      update_assessment_status assessment_id: "0000-0000-0000-0000-0000",
                               assessment_status_body: {
                                 "status": "CANCELLED",
                               },
                               accepted_responses: [200],
                               auth_data: {
                                 scheme_ids: [scheme_id],
                               }

      expect(JSON.parse(response, symbolize_names: true)).to eq(
        { data: "No lodgements during this time frame" },
      )
    end

    it "returns a csv of different assessment types " do
      add_postcodes("A0 0AA", 51.5045, 0.0865, "London")

      lodge_assessment_with_rrn(
        valid_sap_xml,
        "0000-0000-0000-0000-0001",
        "SAP-Schema-18.0.0",
        scheme_id,
        Time.utc(2020, 8, 1),
      )

      lodge_assessment_with_rrn(
        valid_cepc_xml,
        "0000-0000-0000-0000-0002",
        "CEPC-8.0.0",
        scheme_id,
        Time.utc(2020, 8, 2),
      )

      lodge_assessment_with_rrn(
        valid_cepc_rr_xml,
        "0000-0000-0000-0000-0009",
        "CEPC-8.0.0",
        scheme_id,
        Time.utc(2020, 8, 3),
      )

      lodge_assessment_with_rrn(
        valid_dec_xml,
        "0000-0000-0000-0000-0003",
        "CEPC-8.0.0",
        scheme_id,
        Time.utc(2020, 8, 4),
      )

      lodge_assessment_with_rrn(
        valid_dec_rr_xml,
        "0000-0000-0000-0000-0004",
        "CEPC-8.0.0",
        scheme_id,
        Time.utc(2020, 8, 5),
      )

      lodge_assessment_with_rrn(
        valid_ac_cert_xml,
        "0000-0000-0000-0000-0005",
        "CEPC-8.0.0",
        scheme_id,
        Time.utc(2020, 8, 6),
      )

      lodge_assessment_with_rrn(
        valid_ac_report_xml,
        "0000-0000-0000-0000-0006",
        "CEPC-8.0.0",
        scheme_id,
        Time.utc(2020, 8, 7),
      )

      response =
        get_assessment_report(start_date: "2020-08-01", end_date: "2020-08-07")
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

def lodge_assessment_with_rrn(xml, rrn, schema_name, scheme_id, created_at)
  Timecop.freeze(created_at)
  doc = Nokogiri.XML xml

  # Includes commercial certificates excluding DEC
  if schema_name.include?("CEPC") && doc.at("Report-Type").nil?
    doc.at("//CEPC:RRN").content = rrn
  else
    doc.at("RRN").content = rrn
  end
  lodge_assessment(
    assessment_body: doc.to_xml,
    accepted_responses: [201],
    auth_data: {
      scheme_ids: [scheme_id],
    },
    schema_name: schema_name,
  )
end
