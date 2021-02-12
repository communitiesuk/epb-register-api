require "rspec"

describe "AddressMatching" do
  include RSpecRegisterApiServiceMixin

  RDSAP_SCHEMA = "RdSAP-Schema-20.0.0".freeze
  SAP_SCHEMA = "SAP-Schema-18.0.0".freeze

  before(:all) do
    scheme_id = add_scheme_and_get_id
    call_add_assessor(scheme_id)

    rdsap_xml = Nokogiri.XML Samples.xml(RDSAP_SCHEMA, "epc")
    rdsap_xml.at("RRN").children = "0000-0000-0000-0000-0001"
    rdsap_xml.at("RRN").children = "0000-0000-0000-0000-0001"
    sap_xml = Nokogiri.XML Samples.xml(SAP_SCHEMA, "epc")
    sap_xml.at("RRN").children = "0000-0000-0000-0000-0002"
    call_lodge_assessment(scheme_id, RDSAP_SCHEMA, rdsap_xml)
    call_lodge_assessment(scheme_id, SAP_SCHEMA, sap_xml)
  end

  context "When we call the update_address_lines task on two assessments with no address discrepancy" do
    it "Then both assessments addresses should be matched" do
      expect { get_task("update_address_lines").invoke }.to output(
        /0 assessments updated and 2 assessments matched/,
      ).to_stdout
    end
  end

  context "When we call the update_address_lines task with two assessments having address modified" do
    before do
      change_address(assessment_id: "0000-0000-0000-0000-0001", address_line1: "1 John's Street")
      change_address(assessment_id: "0000-0000-0000-0000-0002", address_line2: "2 John's Street")
    end

    it "Then both assessments addresses should be updated" do
      expect { get_task("update_address_lines").invoke }.to output(
        /2 assessments updated and 0 assessments matched/,
      ).to_stdout
    end
  end
end

private

def call_add_assessor(scheme_id)
  add_assessor(
    scheme_id,
    "SPEC000000",
    AssessorStub.new.fetch_request_body(
      nonDomesticNos3: "ACTIVE",
      nonDomesticNos4: "ACTIVE",
      nonDomesticNos5: "ACTIVE",
      nonDomesticDec: "ACTIVE",
      domesticRdSap: "ACTIVE",
      domesticSap: "ACTIVE",
      nonDomesticSp3: "ACTIVE",
      nonDomesticCc4: "ACTIVE",
      gda: "ACTIVE",
    ),
  )
end

def call_lodge_assessment(scheme_id, schema_name, xml_document)
  lodge_assessment(
    assessment_body: xml_document.to_xml,
    accepted_responses: [201],
    auth_data: {
      scheme_ids: [scheme_id],
    },
    override: true,
    schema_name: schema_name,
  )
end
