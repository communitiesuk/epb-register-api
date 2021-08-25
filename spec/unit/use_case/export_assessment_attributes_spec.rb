describe UseCase::ExportAssessmentAttributes do
  context "when exporting data for attribute storage call the use case" do
    subject do
      described_class.new(
        assessments_gateway,
        assessments_search_gateway,
        assessments_xml_gateway,
      )
    end

    let(:assessments_gateway) { instance_double(Gateway::AssessmentsGateway) }
    let(:expected_hash_keys) { %i[address assessor assessment_id] }
    let(:assessments_search_gateway) do
      instance_double(Gateway::AssessmentsSearchGateway)
    end
    let(:assessments_xml_gateway) do
      instance_double(Gateway::AssessmentsXmlGateway)
    end
    let(:cepc_schema) { "CEPC-8.0.0" }
    let(:cepc_xml) { Nokogiri.XML Samples.xml(cepc_schema, "cepc") }
    let(:sap_schema) { "SAP-Schema-18.0.0" }
    let(:sap_xml) { Nokogiri.XML Samples.xml(sap_schema, "epc") }

    # using hash rockets to mimic the hashes created by activerecord whose keys are string and not symbols
    let(:fetch_ids_response) do
      [
        {
          "assessment_id" => "0000-0000-0000-0000-0000",
          "type_of_assessment" => "CEPC",
        },
        {
          "assessment_id" => "0000-0000-0000-0000-0001",
          "type_of_assessment" => "SAP",
        },
      ]
    end
    let(:fetch_cepc_assessment) do
      Domain::AssessmentSearchResult.new(
        address_id: "RRN-0000-0000-0000-0000-0000",
        created_at: "2021-05-01",
        opt_out: false,
      )
    end
    let(:fetch_sap_assessment) do
      Domain::AssessmentSearchResult.new(
        address_id: "RRN-0000-0000-0000-0000-0001",
        created_at: "2021-05-02",
        opt_out: false,
      )
    end

    before do
      allow(assessments_gateway).to receive(:fetch_assessment_ids_by_range)
        .and_return(fetch_ids_response)
      allow(assessments_search_gateway).to receive(:search_by_assessment_id)
        .with("0000-0000-0000-0000-0000")
        .and_return([fetch_cepc_assessment])
      allow(assessments_search_gateway).to receive(:search_by_assessment_id)
        .with("0000-0000-0000-0000-0001")
        .and_return([fetch_sap_assessment])
      allow(assessments_xml_gateway).to receive(:fetch)
        .with("0000-0000-0000-0000-0000")
        .and_return({ xml: cepc_xml, schema_type: cepc_schema })
      allow(assessments_xml_gateway).to receive(:fetch)
        .with("0000-0000-0000-0000-0001")
        .and_return({ xml: sap_xml, schema_type: sap_schema })
    end

    it "calls the execute method to extract xml data from the gateway" do
      export = subject.execute(date_today)

      expect(export[0][:assessment_id]).to eq("0000-0000-0000-0000-0000")
      expect(export[0][:type_of_assessment]).to eq("CEPC")
      expect(export[0][:data]).to be_a(Hash)
      expect(export[0][:data].keys).to include(*expected_hash_keys)
      expect(export[1][:assessment_id]).to eq("0000-0000-0000-0000-0001")
      expect(export[1][:type_of_assessment]).to eq("SAP")
      expect(export[1][:data]).to be_a(Hash)
      expect(export[1][:data].keys).to include(*expected_hash_keys)
    end
  end
end
