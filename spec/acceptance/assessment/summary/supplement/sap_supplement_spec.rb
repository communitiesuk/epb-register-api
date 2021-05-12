# frozen_string_literal: true

require "date"

describe "Acceptance::AssessmentSummary::Supplement::SAP", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    assessor =
      AssessorStub.new.fetch_request_body(
        domesticRdSap: "ACTIVE",
        domesticSap: "ACTIVE",
      )
    add_assessor(scheme_id, "SPEC000000", assessor)

    add_address_base(uprn: "0")

    # DATA SETUP:
    # 0000 = SAP with address ID UPRN-000000000000
    # 0001 = SAP with address ID UPRN-000000000000
    # 0002 = SAP with address ID RRN-0000-0000-0000-0000-0002
    # 0003 = RdSAP with address ID UPRN-000000000000

    lodge_sap(Samples.xml("SAP-Schema-18.0.0"), scheme_id)
    @summary_0000_when_sole_cert =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0000").body,
        symbolize_names: true,
      )
    second_assessment = Nokogiri.XML(Samples.xml("SAP-Schema-18.0.0"))
    second_assessment.at("RRN").content = "0000-0000-0000-0000-0001"
    lodge_sap(second_assessment.to_xml, scheme_id)

    third_assessment = Nokogiri.XML(Samples.xml("SAP-Schema-18.0.0"))
    third_assessment.at("RRN").content = "0000-0000-0000-0000-0002"
    third_assessment.at("UPRN").remove
    lodge_sap(third_assessment.to_xml, scheme_id)

    rdsap_assessment = Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
    rdsap_assessment.at("RRN").content = "0000-0000-0000-0000-0003"
    rdsap_assessment.at("UPRN").content = "UPRN-000000000000"
    lodge_assessment(
      assessment_body: rdsap_assessment.to_xml,
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "RdSAP-Schema-20.0.0",
    )

    @summary_0001 =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0001").body,
        symbolize_names: true,
      )

    @summary_0002 =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0002").body,
        symbolize_names: true,
      )
  end

  context "when getting the assessor data supplement" do
    it "Adds scheme details" do
      scheme = @summary_0000_when_sole_cert.dig(:data, :assessor, :registeredBy)
      expect(scheme[:name]).to eq("test scheme")
      expect(scheme[:schemeId]).to be_a(Integer)
    end

    it "Returns the assessor contact details from the database" do
      contact_details =
        @summary_0000_when_sole_cert.dig(:data, :assessor, :contactDetails)
      expect(contact_details).to eq(
        { telephoneNumber: "111222333", email: "a@b.c" },
      )
    end
  end

  context "when getting the related certificates" do
    it "returns an empty list when there are no related certificates" do
      expect(
        @summary_0000_when_sole_cert.dig(:data, :relatedAssessments),
      ).to eq([])
    end

    it "returns SAP and RdSAP assessments lodged against the same address" do
      related_assessments = @summary_0001.dig(:data, :relatedAssessments)
      related_ids = related_assessments.map { |x| x[:assessmentId] }
      expect(related_ids.count).to eq(2)
      expect(related_ids).to include "0000-0000-0000-0000-0000"
      expect(related_ids).to include "0000-0000-0000-0000-0003"
    end

    it "does not return opted out related assessments" do
      opt_out_assessment("0000-0000-0000-0000-0000")

      @summary_0001 =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0001").body,
          symbolize_names: true,
        )

      related_assessments = @summary_0001.dig(:data, :relatedAssessments)
      expect(related_assessments.count).to eq(1)
      expect(
        related_assessments[0][:assessmentId],
      ).to eq "0000-0000-0000-0000-0003"
    end

    context "when there is no UPRN field" do
      it "returns an empty list when there are no related assessments" do
        expect(@summary_0002.dig(:data, :relatedAssessments)).to eq([])
      end
    end
  end
end

def lodge_sap(xml, scheme_id)
  lodge_assessment(
    assessment_body: xml,
    auth_data: {
      scheme_ids: [scheme_id],
    },
    schema_name: "SAP-Schema-18.0.0",
  )
end
