describe Gateway::HomeEnergyAdviceGateway do
  include RSpecRegisterApiServiceMixin
  subject(:gateway) { described_class.new }

  let(:scheme_id) { add_scheme_and_get_id }

  let(:rdsap_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }
  let(:cepc_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }

  before do
    add_super_assessor(scheme_id: scheme_id)
  end

  context "when expecting to find one RdSAP assessment" do
    before do
      lodge_assessment(
        assessment_body: rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
      )
    end

    let(:expected_result) do
      [{
        assessment_id: "0000-0000-0000-0000-0000",
        address_line1: "1 Some Street",
      }]
    end

    it "finds one record using the postcode and building number" do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
      expect(result).to eq(expected_result)
    end

    it "finds one record using the postcode and building name" do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1 Some Street")
      expect(result).to eq(expected_result)
    end
  end

  context "when there is more than one EPC for the same address" do
    before do
      do_lodgement = lambda {
        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )
      }
      do_lodgement.call
      rdsap_xml.at("RRN").content = "0000-0000-0000-0000-9999"
      do_lodgement.call
    end

    let(:expected_result) do
      [{
        assessment_id: "0000-0000-0000-0000-9999",
        address_line1: "1 Some Street",
      }]
    end

    it "finds the latest EPC for that address (excluding the superseded)", aggregate_failures: true do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
      expect(result).to eq(expected_result)
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1 Some Street")
      expect(result).to eq(expected_result)
    end
  end

  context "when there is more than one result for the same search" do
    before do
      do_lodgement = lambda {
        lodge_assessment(
          assessment_body: rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          override: true,
        )
      }
      do_lodgement.call
      rdsap_xml.at("RRN").content = "0000-0000-0000-0000-9999"
      rdsap_xml.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 Another Street" }
      rdsap_xml.at("UPRN").content = "UPRN-000111222333"
      do_lodgement.call

      cepc_xml.at("//CEPC:RRN").content = "1000-0000-0000-0000-9999"
      cepc_xml.xpath("//*[local-name() = 'Address-Line-1']").each { |node| node.content = "1 Commercial Street" }
      cepc_xml.at("//CEPC:UPRN").content = "UPRN-000111222334"
      lodge_assessment(
        assessment_body: cepc_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
        schema_name: "CEPC-8.0.0",
      )
    end

    let(:expected_result) do
      [{
        assessment_id: "0000-0000-0000-0000-0000",
        address_line1: "1 Some Street",
      },
       {
         assessment_id: "0000-0000-0000-0000-9999",
         address_line1: "1 Another Street",
       }]
    end

    it "finds the 2 domestic EPCs for that address" do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
      expect(result.sort_by { |item| item[:assessment_id] }).to eq(expected_result)
    end

    it "does not find a CEPC for that address" do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1 Commercial Street")
      expect(result).to eq([])
    end
  end

  context "when an address has an empty address line 1" do
    before do
      lodge_assessment(
        assessment_body: rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
      )
      ActiveRecord::Base.connection.exec_query("UPDATE assessments SET address_line2 = '1 Some Street', address_line1= '' ")
    end

    it "finds the EPC for that building number" do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1")
      expect(result.length).to eq(1)
    end

    it "finds the EPC for the same building name" do
      result = gateway.fetch_by_address(postcode: "A0 0AA", building_identifier: "1 Some Street")
      expect(result.length).to eq(1)
    end
  end
end
