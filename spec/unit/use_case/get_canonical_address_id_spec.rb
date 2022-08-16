describe UseCase::GetCanonicalAddressId do
  subject(:use_case) do
    described_class.new address_base_search_gateway:,
                        assessments_address_id_gateway:,
                        assessments_search_gateway:
  end

  let(:assessments_search_gateway) { instance_double Gateway::AssessmentsSearchGateway }
  let(:address_base_search_gateway) { instance_double Gateway::AddressBaseSearchGateway }
  let(:assessments_address_id_gateway) { instance_double Gateway::AssessmentsAddressIdGateway }

  context "when getting the canonical address ID for a CEPC dual lodgement when the UPRN provided does not exist" do
    before do
      allow(address_base_search_gateway).to receive(:check_uprn_exists).and_return(false)
    end

    context "when determining the address ID for the non-report lodgement" do
      let(:params) do
        {
          rrn: "0000-0000-0000-0000-0000",
          related_rrn: "0000-0000-0000-0000-0001",
          type_of_assessment: "CEPC",
          address_id: "UPRN-000000000001",
        }
      end

      it "assigns the address ID based on the RRN of the non-report lodgement" do
        expect(use_case.execute(**params)).to eq "RRN-0000-0000-0000-0000-0000"
      end
    end

    context "when determining the address ID for the report lodgement" do
      let(:params) do
        {
          rrn: "0000-0000-0000-0000-0001",
          related_rrn: "0000-0000-0000-0000-0000",
          type_of_assessment: "CEPC-RR",
          address_id: "UPRN-000000000001",
        }
      end

      it "assigns the address ID based on the RRN of the non-report lodgement" do
        expect(use_case.execute(**params)).to eq "RRN-0000-0000-0000-0000-0000"
      end
    end
  end

  context "when getting the canonical address ID for a CEPC dual lodgement when the UPRN provided exists" do
    before do
      allow(address_base_search_gateway).to receive(:check_uprn_exists).and_return(true)
    end

    context "when determining the address ID for the non-report lodgement" do
      let(:params) do
        {
          rrn: "0000-0000-0000-0000-0000",
          related_rrn: "0000-0000-0000-0000-0001",
          type_of_assessment: "CEPC",
          address_id: "UPRN-000000000001",
        }
      end

      it "assigns the address ID based on the UPRN given" do
        expect(use_case.execute(**params)).to eq "UPRN-000000000001"
      end
    end
  end

  context "when getting the canonical address IDs for an aircon dual assessment when the URPN provided does not exist" do
    before do
      allow(address_base_search_gateway).to receive(:check_uprn_exists).and_return(false)
    end

    context "when getting the address ID for the non-report assessment" do
      let(:params) do
        {
          rrn: "0000-0000-0000-0000-0000",
          related_rrn: "0000-0000-0000-0000-0000",
          type_of_assessment: "AC-CERT",
          address_id: "UPRN-000000000001",
        }
      end

      it "assigns the address ID based on the RRN of the non-report lodgement" do
        expect(use_case.execute(**params)).to eq "RRN-0000-0000-0000-0000-0000"
      end
    end

    context "when getting the address ID for the report assessment" do
      let(:params) do
        {
          rrn: "0000-0000-0000-0000-0001",
          related_rrn: "0000-0000-0000-0000-0000",
          type_of_assessment: "AC-REPORT",
          address_id: "UPRN-000000000001",
        }
      end

      it "assigns the address ID based on the RRN of the non-report lodgement" do
        expect(use_case.execute(**params)).to eq "RRN-0000-0000-0000-0000-0000"
      end
    end
  end
end
