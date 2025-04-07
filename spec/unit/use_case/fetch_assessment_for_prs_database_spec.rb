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
      "expiry_date" => "2030-05-03 00:00:00.000000000 +0000",
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
      "expiry_date" => "2026-05-04 00:00:00.000000000 +0000",
      "address_id" => "UPRN-000000000001",
      "cancelled_at" => nil,
      "not_for_issue_at" => nil,
      "type_of_assessment" => "CEPC",
      "latest_epc_rrn_for_address" => "0000-0000-0000-0000-0001",
    }
  end

  let(:prs_gateway_response_uprn) do
    [{ "address_line1" => "1 Some Street",
       "address_line2" => "",
       "address_line3" => "",
       "address_line4" => "",
       "town" => "Whitbury",
       "postcode" => "SW1A 2AA",
       "current_energy_efficiency_rating" => 50,
       "epc_rrn" => "0123-4567-8901-2345-6789",
       "expiry_date" => "2035-05-03 00:00:00.000000000 +0000",
       "rn" => 1,
       "cancelled_at" => nil,
       "not_for_issue_at" => nil,
       "type_of_assessment" => "RdSAP",
       "latest_epc_rrn_for_address" => "0123-4567-8901-2345-6789" }]
  end

  context "when fetching details for an domestic RRN that exists" do
    it "returns the expected domain object" do
      allow(prs_database_gateway).to receive(:search_by_rrn).with(rrn).and_return prs_gateway_response_rrn
      result = use_case.execute({ rrn: "0123-4567-8901-2345-6789" })

      expect(result).to be_a Domain::AssessmentForPrsDatabaseDetails
    end
  end

  context "when fetching details for a UPRN that exists" do
    it "returns the expected domain object" do
      allow(prs_database_gateway).to receive(:search_by_uprn).with(uprn).and_return prs_gateway_response_uprn
      result = use_case.execute({ uprn: "UPRN-000000000000" })

      expect(result).to be_a Domain::AssessmentForPrsDatabaseDetails
    end
  end

  context "when fetching details for an RRN that does not exist or is not applicable" do
    let(:cepc_rrn) { "0000-0000-0000-0000-0001" }

    it "raises an assessment gone error" do
      allow(prs_database_gateway).to receive(:search_by_rrn).with(rrn).and_return(prs_gateway_response_rrn)
      prs_gateway_response_rrn["cancelled_at"] = "2023-05-04"

      expect { use_case.execute({ rrn: "0123-4567-8901-2345-6789" }) }.to raise_error described_class::AssessmentGone
    end

    it "raises an invalid assessment type error" do
      allow(prs_database_gateway).to receive(:search_by_rrn).with(cepc_rrn).and_return(prs_gateway_response_rrn_non_dom)

      expect { use_case.execute({ rrn: "0000-0000-0000-0000-0001" }) }.to raise_error described_class::InvalidAssessmentTypeException
    end

    it "raises an invalid rrn error" do
      expect { use_case.execute({ rrn: "0000-0000-00-0000-0001" }) }.to raise_error Helper::RrnHelper::RrnNotValid
    end
  end
end
