describe "UseCase::AssessmentSummary::Fetch", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:scheme_id) do
    add_scheme_and_get_id
  end

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

    let(:expected_result) do
      use_case.execute("0000-0000-0000-0000-0000")[:related_assessments]
    end

    before do
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
      related_epc_three = set_xml_date(related_epc_three, Time.now.strftime("%Y-%m-%d"))
      lodge_assessment(
        assessment_body: related_epc_three.to_xml,
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-20.0.0",
      )
    end

    it "returns the a number of related assessments" do
      expect(expected_result.length).to eq(3)
    end

    it "the first related assessment one ordered by date_of_expiry DESC, created_at DESC, assessment_id DESC" do
      expect(expected_result.first.to_hash).to eq({ assessment_expiry_date: "2031-06-20",
                                                    assessment_id: "0000-0000-0000-0000-0003",
                                                    assessment_status: "ENTERED",
                                                    assessment_type: "RdSAP" })
    end

    it "has a superseded rrn that matches the 1st related assessment" do
      expect(use_case.execute("0000-0000-0000-0000-0000")[:superseded_by]).to eq("0000-0000-0000-0000-0003")
    end

    context "when lodging further EPC for the same address" do
      it "produces a new superseded_by value based on expiration date desc" do
        Timecop.freeze(Time.utc(2021, 7, 1))
        later_epc = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        later_epc.at("RRN").content = "0000-0000-0000-0000-9999"
        later_epc = set_xml_date(later_epc, Time.now.strftime("%Y-%m-%d"))
        lodge_assessment(
          assessment_body: later_epc.to_xml,
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
        expect(use_case.execute("0000-0000-0000-0000-0000")[:superseded_by]).to eq("0000-0000-0000-0000-9999")
      end

      it "produces a new superseded_by value based on the created at date being in desc order" do
        Timecop.freeze(Time.utc(2021, 7, 1))
        later_epc = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
        later_epc.at("RRN").content = "0000-0000-0000-0000-5421"
        later_epc = set_xml_date(later_epc, Time.now.strftime("%Y-%m-%d"))
        lodge_assessment(
          assessment_body: later_epc.to_xml,
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
        expect(use_case.execute("0000-0000-0000-0000-0000")[:superseded_by]).to eq("0000-0000-0000-0000-5421")
      end
    end
  end

  context "when an epc has many related epc none which supersede it" do
    subject(:use_case) { UseCase::AssessmentSummary::Fetch.new }

    before do
      add_super_assessor(scheme_id: scheme_id)
      domestic_rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      domestic_rdsap_xml = set_xml_date(domestic_rdsap_xml, Time.now.prev_day(1).strftime("%Y-%m-%d"))
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
    end

    it "does not have a superseded rrn" do
      expect(use_case.execute("0000-0000-0000-0000-0000")[:superseded_by]).to eq(nil)
    end
  end
end

def set_xml_date(epc_xml, date)
  epc_xml.at("Inspection-Date").children = date
  epc_xml.at("Completion-Date").children = date
  epc_xml.at("Registration-Date").children = date
  epc_xml
end
