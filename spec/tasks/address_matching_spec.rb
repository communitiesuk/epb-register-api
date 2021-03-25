require "rspec"

describe "AddressMatching" do
  include RSpecRegisterApiServiceMixin

  RDSAP_SCHEMA = "RdSAP-Schema-19.0".freeze
  SAP_SCHEMA = "SAP-Schema-17.0".freeze

  before(:all) do
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id)

    rdsap_xml = Nokogiri.XML Samples.xml(RDSAP_SCHEMA, "epc")
    rdsap_xml.at("RRN").children = "0000-0000-0000-0000-0001"
    rdsap_xml.at("UPRN").children = "0000000001"

    sap_xml = Nokogiri.XML Samples.xml(SAP_SCHEMA, "epc")
    sap_xml.at("RRN").children = "0000-0000-0000-0000-0002"
    sap_xml.at("UPRN").children = "0000000001"

    call_lodge_assessment(scheme_id, RDSAP_SCHEMA, rdsap_xml, true)
    call_lodge_assessment(scheme_id, SAP_SCHEMA, sap_xml, true)

    HttpStub.enable_webmock
  end

  after(:all) { HttpStub.off }

  let(:assessment_gateway) { Gateway::AssessmentsGateway.new }
  let(:assessment_search_gateway) { Gateway::AssessmentsSearchGateway.new }
  let(:address_id_gateway) { Gateway::AssessmentsAddressIdGateway.new }

  context "When we call the import_address_matching task" do
    before do
      allow(STDOUT).to receive(:puts)
      EnvironmentStub
        .all
        .with("bucket_name", "test-bucket")
        .with("file_name", "uprn_matching.csv")
      HttpStub.s3_get_object("uprn_matching.csv", get_address_matching_csv)
    end

    context "With two addresses using an LPRN belong to the same property" do
      it "Then both address IDs are updated" do
        get_task("import_address_matching").invoke

        assessment1 =
          assessment_search_gateway.search_by_assessment_id(
            "0000-0000-0000-0000-0001",
          ).first
        assessment2 =
          assessment_search_gateway.search_by_assessment_id(
            "0000-0000-0000-0000-0002",
          ).first
        expect(assessment1.get("address_id")).to eq("UPRN-0000000011")
        expect(assessment2.get("address_id")).to eq("UPRN-0000000011")
      end
    end

    context "With an address ID was previously updated by EPBR" do
      before do
        address_id_gateway.update_assessment_address_id_mapping(
          "0000-0000-0000-0000-0001",
          "UPRN-0000000091",
        )
      end

      it "Then the related assessment is not updated" do
        get_task("import_address_matching").invoke

        assessment1 =
          assessment_search_gateway.search_by_assessment_id(
            "0000-0000-0000-0000-0001",
          ).first
        assessment2 =
          assessment_search_gateway.search_by_assessment_id(
            "0000-0000-0000-0000-0002",
          ).first
        expect(assessment1.get("address_id")).to eq("UPRN-0000000091")
        expect(assessment2.get("address_id")).to eq("UPRN-0000000011")
      end
    end
  end

  context "When we call the update_address_lines task" do
    before { allow(STDOUT).to receive(:puts) }

    context "With two assessments having no address discrepancy" do
      it "Then both assessments addresses should be matched" do
        expect { get_task("update_address_lines").invoke }.to output(
          /0 assessments updated and 2 assessments matched/,
        ).to_stdout
      end
    end

    context "With two assessments having modified addresses" do
      before do
        assessment_gateway.update_field(
          "0000-0000-0000-0000-0001",
          "address_line1",
          "1 John's Street",
        )
        assessment_gateway.update_field(
          "0000-0000-0000-0000-0002",
          "address_line1",
          "2 John's Street",
        )
      end

      it "Then both assessments addresses should be updated" do
        expect { get_task("update_address_lines").invoke }.to output(
          /2 assessments updated and 0 assessments matched/,
        ).to_stdout
      end

      it "Then the address in the assessments table should match the XML" do
        get_task("update_address_lines").invoke

        assessment =
          assessment_search_gateway.search_by_assessment_id(
            "0000-0000-0000-0000-0001",
          ).first
        expect(assessment.get("address_line1")).to eq("1 Some Street")
        expect(assessment.get("address_line2")).to eq("")
        expect(assessment.get("address_line3")).to eq("")
        expect(assessment.get("address_line3")).to eq("")
      end
    end
  end
end

private

def get_address_matching_csv
  "lprn,uprn,quality,duplicated\n" \
    "LPRN-0000000001,UPRN-0000000011,GOOD,false\n" \
    "LPRN-0000000002,UPRN-0000000022,GOOD,false\n"
end
