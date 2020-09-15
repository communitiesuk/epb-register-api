# frozen_string_literal: true

require "date"

describe "Acceptance::AssessmentSummary::Supplement::RdSAP" do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    assessor = AssessorStub.new.fetch_request_body(domesticRdSap: "ACTIVE")
    add_assessor(scheme_id, "SPEC000000", assessor)

    lodge_rdsap(Samples.xml("RdSAP-Schema-20.0.0"), scheme_id)
    add_green_deal_plan(
      assessment_id: "0000-0000-0000-0000-0000",
      body: GreenDealPlanStub.new.request_body,
    )
    @regular_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0000").body,
        symbolize_names: true,
      )

    rdsap_without_contacts = Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
    rdsap_without_contacts.at("E-Mail").remove
    rdsap_without_contacts.at("Telephone").remove
    rdsap_without_contacts.at("RRN").content = "0000-0000-0000-0000-0001"
    lodge_rdsap(rdsap_without_contacts.to_xml, scheme_id)
    @second_summary =
      JSON.parse(
        fetch_assessment_summary("0000-0000-0000-0000-0001").body,
        symbolize_names: true,
      )
  end

  context "when getting the assessor data supplement" do
    it "Adds scheme details" do
      scheme = @regular_summary.dig(:data, :assessor, :registeredBy)
      expect(scheme[:name]).to eq("test scheme")
      expect(scheme[:schemeId]).to be_a(Integer)
    end

    it "Returns lodged email and phone values by default" do
      contact_details = @regular_summary.dig(:data, :assessor, :contactDetails)
      expect(contact_details).to eq(
        { telephoneNumber: "0921-19037", email: "a@b.c" },
      )
    end

    it "Overrides missing assessor email and phone values with DB values" do
      expect(@second_summary.dig(:data, :assessor, :contactDetails)).to eq(
        { email: "person@person.com", telephoneNumber: "010199991010101" },
      )
    end
  end

  context "when getting the related certificates" do
    it "Returns an empty list when there are no related certificates" do
      expect(@regular_summary.dig(:data, :relatedAssessments)).to eq([])
    end

    it "Returns assessments lodged against the same address" do
      related_assessments = @second_summary.dig(:data, :relatedAssessments)
      expect(related_assessments.count).to eq(1)
      expect(related_assessments[0][:assessmentId]).to eq(
        "0000-0000-0000-0000-0000",
      )
    end

    it "does not return opted out related assessments" do
      opt_out_assessment("0000-0000-0000-0000-0000")

      @second_summary =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0001").body,
          symbolize_names: true,
        )

      expect(@second_summary.dig(:data, :relatedAssessments)).to eq([])
    end
  end

  context "when getting the green deal plan" do
    it "does not add a green deal plan when there isn't one" do
      expect(@second_summary.dig(:data, :greenDealPlan)).to be_nil
    end

    it "adds a green deal plan when there is one" do
      green_deal_plan = @regular_summary.dig(:data, :greenDealPlan)
      expect(green_deal_plan[:ccaRegulated]).to be_truthy
      expect(green_deal_plan[:chargeUplift]).to eq(
        { amount: "1.25", date: "2025-03-29" },
      )
      expect(green_deal_plan[:charges]).to eq(
        [
          {
            dailyCharge: 0.34,
            endDate: "2030-03-29",
            sequence: 0,
            startDate: "2020-03-29",
          },
        ],
      )
      expect(green_deal_plan[:endDate]).to eq("2030-02-28")
      expect(green_deal_plan[:estimatedSavings]).to eq(1566)
      expect(green_deal_plan[:greenDealPlanId]).to eq("ABC123456DEF")
      expect(green_deal_plan[:interest]).to eq({ fixed: true, rate: "12.3" })
      expect(green_deal_plan[:measures]).to eq(
        [
          {
            measureType: "Loft insulation",
            product: "WarmHome lagging stuff (TM)",
            repaidDate: "2025-03-29",
            sequence: 0,
          },
        ],
      )
      expect(green_deal_plan[:measuresRemoved]).to be_falsey
      expect(green_deal_plan[:providerDetails]).to eq(
        {
          email: "lender@example.com",
          name: "The Bank",
          telephone: "0800 0000000",
        },
      )
      expect(green_deal_plan[:savings]).to eq(
        [
          { fuelCode: "39", fuelSaving: 23_253, standingChargeFraction: 0 },
          { fuelCode: "40", fuelSaving: -6331, standingChargeFraction: -0.9 },
          { fuelCode: "41", fuelSaving: -15_561, standingChargeFraction: 0 },
        ],
      )
      expect(green_deal_plan[:startDate]).to eq("2020-01-30")
      expect(green_deal_plan[:structureChanged]).to be_falsey
    end
  end
end

def lodge_rdsap(xml, scheme_id)
  lodge_assessment(
    assessment_body: xml,
    auth_data: { scheme_ids: [scheme_id] },
    schema_name: "RdSAP-Schema-20.0.0",
  )
end
