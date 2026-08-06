describe UseCase::FetchAssessmentForPrsDatabase do
  subject(:use_case) { described_class.new(prs_database_gateway: prs_database_gateway) }

  let(:prs_database_gateway) { instance_double(Gateway::PrsDatabaseGateway) }

  let(:rrn) { "0123-4567-8901-2345-6789" }
  let(:uprn) { "UPRN-000000000000" }

  let(:prs_gateway_response_rrn) do
    {
      "address_line1" => "1 Some Street",
      "address_line2" => "",
      "address_line3" => "",
      "address_line4" => "",
      "town" => "Whitbury",
      "postcode" => "SW1A 2AA",
      "current_energy_efficiency_rating" => 50,
      "epc_rrn" => "0123-4567-8901-2345-6789",
      "expiry_date" => "2030-05-03",
      "address_id" => "UPRN-000000000000",
      "cancelled_at" => nil,
      "not_for_issue_at" => nil,
      "type_of_assessment" => "RdSAP",
      "latest_epc_rrn_for_address" => "0000-0000-0000-0000-0002",
    }
  end

  let(:prs_gateway_response_rrn_non_dom) do
    {
      "address_line1" => "Some Unit",
      "address_line2" => "2 Lonely Street",
      "address_line3" => "Some Area",
      "address_line4" => "Some Area",
      "town" => "Whitbury",
      "postcode" => "SW1A 2AA",
      "current_energy_efficiency_rating" => 80,
      "epc_rrn" => "0000-0000-0000-0000-0001",
      "expiry_date" => "2026-05-04",
      "address_id" => "UPRN-000000000001",
      "cancelled_at" => nil,
      "not_for_issue_at" => nil,
      "type_of_assessment" => "CEPC",
      "latest_epc_rrn_for_address" => "0000-0000-0000-0000-0001",
    }
  end

  let(:prs_gateway_response_uprn) do
    { "address_line1" => "1 Some Street",
      "address_line2" => "",
      "address_line3" => "",
      "address_line4" => "",
      "town" => "Whitbury",
      "postcode" => "SW1A 2AA",
      "current_energy_efficiency_rating" => 50,
      "epc_rrn" => "0123-4567-8901-2345-6789",
      "expiry_date" => "2035-05-03",
      "rn" => 1,
      "cancelled_at" => nil,
      "not_for_issue_at" => nil,
      "type_of_assessment" => "RdSAP",
      "latest_epc_rrn_for_address" => "0123-4567-8901-2345-6789" }
  end

  context "when fetching details for a UPRN that exists" do
    it "returns the expected domain object" do
      allow(prs_database_gateway).to receive(:search_by_uprn).with(uprn).and_return prs_gateway_response_uprn
      result = use_case.execute(uprn:)

      expect(result).to be_a Domain::AssessmentForPrsDatabaseDetails
    end
  end

  context "when fetching details for a non-existance UPRN" do
    it "raises a not found exception" do
      allow(prs_database_gateway).to receive(:search_by_uprn).with(uprn).and_return nil
      expect { use_case.execute(uprn:) }.to raise_error described_class::NotFoundException
    end
  end

  context "when fetching details for an domestic RRN that exists" do
    it "returns the expected domain object" do
      allow(prs_database_gateway).to receive(:search_by_rrn).with(rrn).and_return prs_gateway_response_rrn
      result = use_case.execute(rrn:)

      expect(result).to be_a Domain::AssessmentForPrsDatabaseDetails
    end
  end

  context "when fetching details for an invalid RRN number" do
    it "raises an invalid rrn error" do
      expect { use_case.execute(rrn: "0000-0000-00-0000-0001") }.to raise_error Helper::RrnHelper::RrnNotValid
    end
  end

  context "when fetching details for a non-existance rrn" do
    it "raises a not found exception" do
      allow(prs_database_gateway).to receive(:search_by_rrn).with(rrn).and_return nil
      expect { use_case.execute(rrn:) }.to raise_error described_class::NotFoundException
    end
  end

  context "when fetching details for a non-domestic certificate" do
    it "raises a not found exception" do
      allow(prs_database_gateway).to receive(:search_by_rrn).with(rrn).and_return prs_gateway_response_rrn_non_dom
      expect { use_case.execute(rrn:) }.to raise_error described_class::InvalidAssessmentTypeException
    end
  end
end
