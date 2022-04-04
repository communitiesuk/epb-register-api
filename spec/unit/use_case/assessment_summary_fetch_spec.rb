describe "UseCase::AssessmentSummary::Fetch", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  context "when extracting summary assessment data for a single certificate" do
    subject(:use_case) { UseCase::AssessmentSummary::Fetch.new(search_gateway: search_gateway, xml_gateway: xml_gateway) }

    let(:search_gateway) do
      instance_double(Gateway::AssessmentsSearchGateway)
    end
    let(:scheme_id) do
      add_scheme_and_get_id
    end
    let(:xml_data) do
      {
        xml: xml_fixture,
        schema_type: "RdSAP-Schema-20.0.0",
        assessment_id: "0000-0000-0000-0000-0000",
        scheme_assessor_id: "SPEC000000",
      }
    end
    let(:xml_fixture) do
      Samples.xml "RdSAP-Schema-20.0.0"
    end
    let(:search_results) do
      [{
        "assessment_id" => "0000-0000-0000-0000-0000",
        "date_of_assessment" => "01-01-2021",
        "type_of_assessment" => "RdSAP",
      }]
    end

    let(:xml_gateway) do
      instance_double(Gateway::AssessmentsXmlGateway)
    end

    before do
      add_super_assessor(scheme_id: scheme_id)

      allow(search_gateway).to receive(:search_by_assessment_id).and_return(search_results)
      allow(xml_gateway).to receive(:fetch).and_return(xml_data)
    end

    it "can load the class as expected" do
      expect { use_case }.not_to raise_error
    end

    it "can execute and return the expected hash" do
      results = use_case.execute("0000-0000-0000-0000-0001")
      expect(results).to eq(SummaryStub.fetch_summary(scheme_id))
    end
  end

  context "when extracting summary assessment data for an EPC with many related assessments" do
    subject(:use_case) { UseCase::AssessmentSummary::Fetch.new }

    before do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id: scheme_id)
      domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      domestic_rdsap_xml = set_xml_date(domestic_rdsap_xml, Time.now.prev_day(2).strftime("%Y-%m-%d"))
      lodge_assessment(
        assessment_body: domestic_rdsap_xml.to_xml,
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-20.0.0",
      )
      related_epc_one = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      related_epc_one.at("RRN").content = "0000-0000-0000-0000-0001"
      related_epc_one = set_xml_date(related_epc_one, Time.now.prev_day(4).strftime("%Y-%m-%d"))
      lodge_assessment(
        assessment_body: related_epc_one.to_xml,
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-20.0.0",
      )

      related_epc_two = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      related_epc_two.at("RRN").content = "0000-0000-0000-0000-0002"
      related_epc_two = set_xml_date(related_epc_two, Time.now.prev_day(5).strftime("%Y-%m-%d"))
      lodge_assessment(
        assessment_body: related_epc_two.to_xml,
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-20.0.0",
      )

      related_epc_three = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      related_epc_three.at("RRN").content = "0000-0000-0000-0000-0003"

      lodge_assessment(
        assessment_body: related_epc_three.to_xml,
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-20.0.0",
      )
    end

    let(:expected_result) do
      use_case.execute("0000-0000-0000-0000-0000")[:related_assessments]
    end

    it "returns the a number of related assessments" do
      expect(expected_result.length).to eq(3)
    end

    it "the first related assessment one ordered by date_of_expiry DESC, created_at DESC, assessment_id DESC" do
      expect(expected_result.first.to_hash).to eq({ assessment_expiry_date: "2031-06-16",
                                                    assessment_id: "0000-0000-0000-0000-0001",
                                                    assessment_status: "ENTERED",
                                                    assessment_type: "RdSAP" })
    end
  end
end

def set_xml_date(epc_xml, date)
  epc_xml.at("Inspection-Date").children = date
  epc_xml.at("Completion-Date").children = date
  epc_xml.at("Registration-Date").children = date
  epc_xml
end
