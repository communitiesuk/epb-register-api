describe UseCase::BulkLinkAssessments do
  subject(:use_case) { described_class.new(fetch_assessments_to_link_gateway: fetch_gateway, address_base_gateway:, assessments_address_id_gateway:) }

  describe "#execute" do
    let(:fetch_gateway) { instance_double Gateway::FetchAssessmentsToLinkGateway }
    let(:address_base_gateway) { instance_double Gateway::AddressBaseSearchGateway }
    let(:assessments_address_id_gateway) { instance_double Gateway::AssessmentsAddressIdGateway }
    let(:number_of_groups) { 3 }

    let(:domain) { instance_double Domain::AssessmentsToLink }

    before do
      allow(fetch_gateway).to receive(:drop_table)
      allow(fetch_gateway).to receive(:create_and_populate_temp_table)
      allow(fetch_gateway).to receive(:get_max_group_id).and_return(number_of_groups)
      allow(fetch_gateway).to receive(:fetch_assessments_by_group_id).and_return domain
      allow(Domain::AssessmentsToLink).to receive(:new).and_return(domain)
      allow(domain).to receive(:set_best_address_id)
      allow(domain).to receive(:best_address_id)
      allow(domain).to receive(:get_assessment_ids)
      allow(address_base_gateway).to receive(:check_uprn_exists).with("UPRN-000000000001").and_return true
      allow(assessments_address_id_gateway).to receive(:update_assessments_address_id_mapping)
      use_case.execute
    end

    it "calls the gateway to fetch the assessment which require linking" do
      expect(fetch_gateway).to have_received(:create_and_populate_temp_table)
    end

    it "calls the gateway and gets the max group_id number" do
      expect(fetch_gateway).to have_received(:get_max_group_id)
    end

    it "calls the gateway to fetch assessments with the same address and postcode for each group" do
      expect(fetch_gateway).to have_received(:fetch_assessments_by_group_id).exactly(number_of_groups).times
    end

    it "set the address_id for each group" do
      expect(domain).to have_received(:set_best_address_id).exactly(number_of_groups).times
    end

    it "calls the gateway to update the address_id for each group" do
      expect(assessments_address_id_gateway).to have_received(:update_assessments_address_id_mapping).exactly(number_of_groups).times
    end
  end

  context "when there are no assessments to link" do
    let(:fetch_gateway) { instance_double Gateway::FetchAssessmentsToLinkGateway }
    let(:address_base_gateway) { instance_double Gateway::AddressBaseSearchGateway }
    let(:assessments_address_id_gateway) { instance_double Gateway::AssessmentsAddressIdGateway }

    let(:domain) { instance_double Domain::AssessmentsToLink }

    before do
      allow(fetch_gateway).to receive(:drop_table)
      allow(fetch_gateway).to receive(:create_and_populate_temp_table)
      allow(fetch_gateway).to receive(:get_max_group_id).and_return(nil)
      allow(fetch_gateway).to receive(:fetch_assessments_by_group_id)
      use_case.execute
    end

    it "returns nil" do
      expect(use_case.execute).to eq nil
    end

    it "does not call the gateway to fetch assessments with the same address and postcode for each group" do
      expect(fetch_gateway).not_to have_received(:fetch_assessments_by_group_id)
    end
  end
end
