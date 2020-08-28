# frozen_string_literal: true

require "date"

describe "Acceptance::AssessmentSummary::Supplement::RdSAP" do
  include RSpecRegisterApiServiceMixin

  context "when getting the assessor data supplement" do
    let(:summary) { lodge_rdsap(Samples.xml("RdSAP-Schema-20.0.0")) }

    it "Adds scheme details" do
      scheme = summary.dig(:data, :assessor, :registeredBy)
      expect(scheme[:name]).to eq("test scheme")
      expect(scheme[:schemeId]).to be_a(Integer)
    end

    it "Returns lodged email and phone values by default" do
      contact_details = summary.dig(:data, :assessor, :contactDetails)
      expect(contact_details).to eq(
        { telephoneNumber: "0921-19037", email: "a@b.c" },
      )
    end

    it "Overrides missing assessor email and phone values with DB values" do
      rdsap_without_contacts = Nokogiri.XML(Samples.xml("RdSAP-Schema-20.0.0"))
      rdsap_without_contacts.at("E-Mail").remove
      rdsap_without_contacts.at("Telephone").remove
      response = lodge_rdsap(rdsap_without_contacts.to_xml)
      expect(response.dig(:data, :assessor, :contactDetails)).to eq(
        { email: "person@person.com", telephoneNumber: "010199991010101" },
      )
    end
  end
end

def lodge_rdsap(xml)
  scheme_id = add_scheme_and_get_id
  assessor = AssessorStub.new.fetch_request_body(domesticRdSap: "ACTIVE")
  add_assessor(scheme_id, "SPEC000000", assessor)
  lodge_assessment(
    assessment_body: xml,
    auth_data: { scheme_ids: [scheme_id] },
    schema_name: "RdSAP-Schema-20.0.0",
  )

  JSON.parse(
    fetch_assessment_summary("0000-0000-0000-0000-0000").body,
    symbolize_names: true,
  )
end
