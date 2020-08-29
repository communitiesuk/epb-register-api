# frozen_string_literal: true

require "date"

describe "Acceptance::AssessmentSummary::Supplement::RdSAP" do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    assessor = AssessorStub.new.fetch_request_body(domesticRdSap: "ACTIVE")
    add_assessor(scheme_id, "SPEC000000", assessor)

    rdsap_without_contacts = Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
    rdsap_without_contacts.at("E-Mail").remove
    rdsap_without_contacts.at("Telephone").remove
    rdsap_without_contacts.at("RRN").content = "0000-0000-0000-0000-0001"

    @regular_summary =
      lodge_rdsap(Samples.xml("RdSAP-Schema-20.0.0"), scheme_id)
    @no_contacts_summary = lodge_rdsap(rdsap_without_contacts.to_xml, scheme_id)
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
      expect(@no_contacts_summary.dig(:data, :assessor, :contactDetails)).to eq(
        { email: "person@person.com", telephoneNumber: "010199991010101" },
      )
    end
  end

  context "when getting the related certificates" do
    it "Returns an empty list when there are no related certificates" do
      expect(@regular_summary.dig(:data, :relatedAssessments)).to eq([])
    end

    it "Returns assessments lodged against the same address" do
      related_assessments = @no_contacts_summary.dig(:data, :relatedAssessments)
      expect(related_assessments.count).to eq(1)
      expect(related_assessments[0][:assessmentId])
          .to eq("0000-0000-0000-0000-0000")
    end
  end
end

def lodge_rdsap(xml, scheme_id)
  lodge_assessment(
    assessment_body: xml,
    auth_data: { scheme_ids: [scheme_id] },
    schema_name: "RdSAP-Schema-20.0.0",
  )

  assessment_id = Nokogiri.XML(xml).at("RRN").content
  JSON.parse(
    fetch_assessment_summary(assessment_id).body,
    symbolize_names: true,
  )
end
