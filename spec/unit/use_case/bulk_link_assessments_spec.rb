require "sentry-ruby"

describe UseCase::BulkLinkAssessments do
  subject(:use_case) { described_class.new(fetch_assessments_to_link_gateway: fetch_gateway, address_base_gateway:, assessments_address_id_gateway:) }

  describe "#execute" do
    let(:fetch_gateway) { instance_double Gateway::FetchAssessmentsToLinkGateway }
    let(:address_base_gateway) { instance_double Gateway::AddressBaseSearchGateway }
    let(:assessments_address_id_gateway) { instance_double Gateway::AssessmentsAddressIdGateway }
    let(:number_of_groups) { 3 }

    let(:domain) { instance_double Domain::AssessmentsToLink }

    before do
      data = [
        { "assessment_id" => "0000-0000-0000-0000-0003", "address_id" => "RRN-0000-0000-0000-0000-0003", "date_registered" => Time.utc(2020, 0o5, 0o4) },
        { "assessment_id" => "0000-0000-0000-0000-0004", "address_id" => "RRN-0000-0000-0000-0000-0004", "date_registered" => Time.utc(2020, 0o5, 0o4) },
      ]
      allow(fetch_gateway).to receive(:drop_table)
      allow(fetch_gateway).to receive(:create_and_populate_temp_table)
      allow(fetch_gateway).to receive(:get_max_group_id).and_return(number_of_groups)
      allow(fetch_gateway).to receive(:fetch_assessments_by_group_id).and_return domain
      allow(Domain::AssessmentsToLink).to receive(:new).and_return(domain)
      allow(domain).to receive(:data).and_return data
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

  context "when fetching linked assessments return no data" do
    let(:fetch_gateway) { instance_double Gateway::FetchAssessmentsToLinkGateway }
    let(:address_base_gateway) { instance_double Gateway::AddressBaseSearchGateway }
    let(:assessments_address_id_gateway) { instance_double Gateway::AssessmentsAddressIdGateway }
    let(:number_of_groups) { 2 }
    let(:data_2) do
      [
        { "assessment_id" => "0000-0000-0000-0000-0003", "address_id" => "RRN-0000-0000-0000-0000-0003", "date_registered" => Time.utc(2020, 0o5, 0o4) },
        { "assessment_id" => "0000-0000-0000-0000-0004", "address_id" => "RRN-0000-0000-0000-0000-0004", "date_registered" => Time.utc(2020, 0o5, 0o4) },
      ]
    end

    let(:domain_2_result) { Domain::AssessmentsToLink.new(data: data_2) }

    before do
      allow(fetch_gateway).to receive(:drop_table)
      allow(fetch_gateway).to receive(:create_and_populate_temp_table)
      allow(fetch_gateway).to receive(:get_max_group_id).and_return(number_of_groups)
      allow(fetch_gateway).to receive(:fetch_assessments_by_group_id).with(1).and_raise Boundary::NoData.new("bulk linking assessment group_id: 1")
      allow(fetch_gateway).to receive(:fetch_assessments_by_group_id).with(2).and_return domain_2_result
      allow(domain_2_result).to receive(:set_best_address_id)
      allow(domain_2_result).to receive(:best_address_id)
      allow(domain_2_result).to receive(:get_assessment_ids)
      allow(address_base_gateway).to receive(:check_uprn_exists).with("UPRN-000000000001").and_return true
      allow(assessments_address_id_gateway).to receive(:update_assessments_address_id_mapping)
      allow(Sentry).to receive(:capture_exception)
    end

    it "does not raise an error" do
      expect { use_case.execute }.not_to raise_error
    end

    it "calls the gateway to fetch assessments gateway for each group" do
      use_case.execute
      expect(fetch_gateway).to have_received(:fetch_assessments_by_group_id).exactly(number_of_groups).times
    end

    it "send a no data error to sentry when fetching assessments to be linked " do
      use_case.execute
      expect(Sentry).to have_received(:capture_exception).with(Boundary::NoData).exactly(1).times
    end

    it "calls the gateway to update the address_ids when there is data", aggregate_failures: true do
      use_case.execute
      expect(domain_2_result).to have_received(:set_best_address_id).exactly(1).times
      expect(assessments_address_id_gateway).to have_received(:update_assessments_address_id_mapping).exactly(1).times
    end
  end
end
