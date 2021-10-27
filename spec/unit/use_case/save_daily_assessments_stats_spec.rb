describe UseCase::SaveDailyAssessmentsStats do
  subject(:use_case) do
    described_class.new(assessment_statistics_gateway: statistics_gateway, assessments_gateway: assessments_gateway, assessments_xml_gateway: assessments_xml_gateway)
  end

  let(:statistics_gateway) { instance_double(Gateway::AssessmentStatisticsGateway) }
  let(:assessments_gateway) { instance_double(Gateway::AssessmentsGateway) }
  let(:assessments_xml_gateway) { instance_double(Gateway::AssessmentsXmlGateway) }

  context "when deriving the statistics for a given date" do
    before do
      allow(statistics_gateway).to receive(:save)
      allow(assessments_gateway).to receive(:fetch_assessments_by_date).and_return(
        [
          { "assessment_id" => "0000-0000-0000-0000", "assessment_type" => "RdSAP", "scheme_id": 1 },
          { "assessment_id" => "0000-0000-0000-0001", "assessment_type" => "SAP", "scheme_id": 1 },
          { "assessment_id" => "0000-0000-0000-0002", "assessment_type" => "SAP", "scheme_id": 2 },
          { "assessment_id" => "0000-0000-0000-0003", "assessment_type" => "SAP", "scheme_id": 2 },
          { "assessment_id" => "0000-0000-0000-0004", "assessment_type" => "SAP", "scheme_id": 2 },
        ],
      )
      rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      sap_xml = Nokogiri.XML Samples.xml("SAP-Schema-18.0.0")
      allow(assessments_xml_gateway).to receive(:fetch).with("0000-0000-0000-0000").and_return({ "xml" => rdsap_xml, "schema_type" => "RdSAP-Schema-20.0.0" })
      allow(assessments_xml_gateway).to receive(:fetch).with("0000-0000-0000-0001").and_return({ "xml" => sap_xml, "schema_type" => "SAP-Schema-18.0.0" })
      sap_xml_thirty = sap_xml.clone
      energy_rating =  sap_xml_thirty.at("Energy-Rating-Current")
      energy_rating.children = "30"
      allow(assessments_xml_gateway).to receive(:fetch).with("0000-0000-0000-0002").and_return({ "xml" => sap_xml_thirty, "schema_type" => "SAP-Schema-18.0.0" })
      allow(assessments_xml_gateway).to receive(:fetch).with("0000-0000-0000-0003").and_return({ "xml" => sap_xml, "schema_type" => "SAP-Schema-18.0.0" })
      sap_xml_eighty_nine = sap_xml.clone
      energy_rating = sap_xml_eighty_nine.at("Energy-Rating-Current")
      energy_rating.children = "89"
      transaction_type = sap_xml_eighty_nine.at("Transaction-Type")
      transaction_type.children = "2"
      allow(assessments_xml_gateway).to receive(:fetch).with("0000-0000-0000-0004").and_return({ "xml" => sap_xml_eighty_nine, "schema_type" => "SAP-Schema-18.0.0" })
    end

    it "calculates the average and groups them by assessment type, scheme id and transaction type" do
      expect(use_case.execute(date: "2021-10-25")).to eq(
        [
          {
            assessment_type: "RdSAP",
            assessments_count: 1,
            rating_average: 50,
            scheme_id: 1,
            transaction_type: "1",
          },
          {
            assessment_type: "SAP",
            assessments_count: 1,
            rating_average: 50,
            scheme_id: 1,
            transaction_type: "1",
          },
          {
            assessment_type: "SAP",
            assessments_count: 2,
            rating_average: 40,
            scheme_id: 2,
            transaction_type: "1",
          },
          {
            assessment_type: "SAP",
            assessments_count: 1,
            rating_average: 89,
            scheme_id: 2,
            transaction_type: "2",
          },
        ],
      )
      expect(assessments_xml_gateway).to have_received(:fetch).exactly(5).times
    end

    it "allows for filter by specified assessment types" do
      allow(assessments_gateway).to receive(:fetch_assessments_by_date).with(date: "2021-10-25", assessment_types: %w[RdSAP]).and_return(
        [{ "assessment_id" => "0000-0000-0000-0000", "assessment_type" => "RdSAP", "scheme_id": 1 }],
      )

      use_case.execute(date: "2021-10-25", assessment_types: %w[RdSAP])
      expect(assessments_gateway).to have_received(:fetch_assessments_by_date).with(date: "2021-10-25", assessment_types: %w[RdSAP])
    end
  end

  context "when deriving the statistics for assessments which don't have rating or transaction type" do
    before do
      allow(statistics_gateway).to receive(:save)
      allow(assessments_gateway).to receive(:fetch_assessments_by_date).and_return(
        [
          { "assessment_id" => "0000-0000-0000-0000", "assessment_type" => "RdSAP", "scheme_id": 1 },
          { "assessment_id" => "0000-0000-0000-0001", "assessment_type" => "AC-Report", "scheme_id": 1 },
        ],
      )
      rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
      ac_report_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "ac-report")
      allow(assessments_xml_gateway).to receive(:fetch).with("0000-0000-0000-0000").and_return({ "xml" => rdsap_xml, "schema_type" => "RdSAP-Schema-20.0.0" })
      allow(assessments_xml_gateway).to receive(:fetch).with("0000-0000-0000-0001").and_return({ "xml" => ac_report_xml, "schema_type" => "CEPC-8.0.0" })
    end

    it "calculates the average and groups them by assessment type, scheme id and transaction type" do
      expect(use_case.execute(date: "2021-10-25")).to eq(
        [
          {
            assessment_type: "RdSAP",
            assessments_count: 1,
            rating_average: 50,
            scheme_id: 1,
            transaction_type: "1",
          },
          {
            assessment_type: "AC-Report",
            assessments_count: 1,
            rating_average: nil,
            scheme_id: 1,
            transaction_type: nil,
          },
        ],
      )
    end
  end
end
