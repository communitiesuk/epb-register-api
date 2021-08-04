# frozen_string_literal: true

require "date"

green_deal_plan_id = "SPC123456SPC"

describe "Acceptance::AssessmentSummary::Supplement::RdSAP",
         set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    green_deal_plan_id
    assessor =
      AssessorStub.new.fetch_request_body(
        domesticRdSap: "ACTIVE",
        domesticSap: "ACTIVE",
      )
    add_assessor(scheme_id, "SPEC000000", assessor)

    # DATA SETUP:
    # 0000 = RdSAP with address ID UPRN-000000000000
    # 0001 = RdSAP with address ID UPRN-000000000000, no contact details
    # 0002 = RdSAP with address ID RRN-0000-0000-0000-0000-0002
    # 0003 = SAP with address ID UPRN-000000000000

    lodge_rdsap(Samples.xml("RdSAP-Schema-20.0.0"), scheme_id)
    add_green_deal_plan(
      assessment_id: "0000-0000-0000-0000-0000",
      body: GreenDealPlanStub.new.request_body(green_deal_plan_id),
    )

    rdsap_without_contacts = Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
    rdsap_without_contacts.at("E-Mail").remove
    rdsap_without_contacts.at("Telephone").remove
    rdsap_without_contacts.at("RRN").content = "0000-0000-0000-0000-0001"
    lodge_rdsap(rdsap_without_contacts.to_xml, scheme_id)

    rdsap_without_uprn = Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
    rdsap_without_uprn.at("RRN").content = "0000-0000-0000-0000-0002"
    rdsap_without_uprn.at("UPRN").remove
    lodge_rdsap(rdsap_without_uprn.to_xml, scheme_id)

    sap_assessment = Nokogiri.XML(Samples.xml("SAP-Schema-18.0.0"))
    sap_assessment.at("RRN").content = "0000-0000-0000-0000-0003"
    sap_assessment.at("UPRN").content = "UPRN-000000000000"
    lodge_assessment(
      assessment_body: sap_assessment.to_xml,
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "SAP-Schema-18.0.0",
    )

    @summary0000 =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0000").body,
        symbolize_names: true,
      )
    @summary0001 =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0001").body,
        symbolize_names: true,
      )
    @summary0002 =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0002").body,
        symbolize_names: true,
      )
  end

  context "when getting the assessor data supplement" do
    it "Adds scheme details" do
      scheme = @summary0000.dig(:data, :assessor, :registeredBy)
      expect(scheme[:name]).to eq("test scheme")
      expect(scheme[:schemeId]).to be_a(Integer)
    end

    it "Returns lodged email and phone values by default" do
      contact_details = @summary0000.dig(:data, :assessor, :contactDetails)
      expect(contact_details).to eq(
        { telephoneNumber: "0555 497 2848", email: "a@b.c" },
      )
    end

    it "Overrides missing assessor email and phone values with DB values" do
      expect(@summary0001.dig(:data, :assessor, :contactDetails)).to eq(
        { email: "person@person.com", telephoneNumber: "010199991010101" },
      )
    end
  end

  context "when getting the related certificates" do
    it "returns an empty list when there are no related certificates" do
      expect(@summary0002.dig(:data, :relatedAssessments)).to eq([])
    end

    it "returns SAP and RdSAP assessments lodged against the same address" do
      related_assessments = @summary0001.dig(:data, :relatedAssessments)
      related_ids = related_assessments.map { |x| x[:assessmentId] }
      expect(related_ids.sort).to contain_exactly("0000-0000-0000-0000-0000", "0000-0000-0000-0000-0003")
    end

    it "does not return opted out related assessments" do
      opt_out_assessment("0000-0000-0000-0000-0000")

      @summary0001 =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0001").body,
          symbolize_names: true,
        )

      related_assessments = @summary0001.dig(:data, :relatedAssessments)
      expect(related_assessments).to match [
        a_hash_including(assessmentId: "0000-0000-0000-0000-0003"),
      ]
    end

    context "when there is no UPRN field" do
      it "returns an empty list when there are no related assessments" do
        expect(@summary0002.dig(:data, :relatedAssessments)).to eq([])
      end
    end
  end

  context "when getting the green deal plan" do
    it "adds a green deal plan when there is one" do
      green_deal_plan = @summary0000.dig(:data, :greenDealPlan).first
      expect(green_deal_plan[:savings].find { |saving| saving[:fuelCode] == "41" }[:fuelSaving]).to eq(-15_561)
    end

    it "adds a green deal plan for subsequent certificates for the same address" do
      expect(@summary_0001.dig(:data, :greenDealPlan)).to match [a_hash_including(greenDealPlanId: green_deal_plan_id)]
    end

    it "does not add a green deal plan for a subsequent certificate for a different address" do
      expect(@summary_0002.dig(:data, :greenDealPlan)).to eq []
    end
  end
end

def lodge_rdsap(xml, scheme_id)
  lodge_assessment(
    assessment_body: xml,
    auth_data: {
      scheme_ids: [scheme_id],
    },
    schema_name: "RdSAP-Schema-20.0.0",
  )
end
