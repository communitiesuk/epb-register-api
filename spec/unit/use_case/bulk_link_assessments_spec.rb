describe UseCase::BulkLinkAssessments do
  subject(:use_case) { described_class.new(fetch_assessments_to_link_gateway: fetch_gateway) }

  describe "#execute" do
    let(:fetch_gateway) { instance_double Gateway::FetchAssessmentsToLinkGateway }
    let(:number_of_groups) { 3 }
    let(:group_1_array) do
      [
        ["0000-0000-0000-0000-0012", "RRN-0000-0000-0000-0000-0012", Time.utc(2020, 0o5, 20)],
        ["0000-0000-0000-0000-0000", "UPRN-000000000001", Time.utc(2020, 0o5, 0o4)],
        ["0000-0000-0000-0000-0001", "UPRN-000000000001", Time.utc(2020, 0o5, 0o5)],
        ["0000-0000-0000-0000-0002", "RRN-0000-0000-0000-0000-0002", Time.utc(2020, 0o5, 0o4)],
      ]
    end

    before do
      allow(fetch_gateway).to receive(:create_and_populate_temp_table)
      allow(fetch_gateway).to receive(:get_max_group_id).and_return(number_of_groups)
      allow(fetch_gateway).to receive(:fetch_by_group_id)
      allow(fetch_gateway).to receive(:fetch_by_group_id).with(1).and_return(group_1_array)
      use_case.execute
    end

    it "calls the gateway to fetch the assessment which require linking" do
      expect(fetch_gateway).to have_received(:create_and_populate_temp_table)
    end

    it "calls the gateway and gets the max group_id number" do
      expect(fetch_gateway).to have_received(:get_max_group_id)
    end

    it "calls the gateway to fetch assessments with the same address and postcode for each group" do
      expect(fetch_gateway).to have_received(:fetch_by_group_id).exactly(number_of_groups).times
    end
  end
end
