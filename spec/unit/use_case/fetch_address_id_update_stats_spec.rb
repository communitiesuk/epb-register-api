describe UseCase::FetchAddressIdUpdateStats do
  subject(:use_case) { described_class.new(stats_gateway) }

  let(:stats_gateway)  do
    instance_double(Gateway::AssessmentsAddressIdGateway)
  end

  before do
    allow(stats_gateway).to receive_messages(fetch_updated_group_count: 1, fetch_updated_address_id_count: 2)
    Timecop.freeze(2024, 12, 22, 0, 0, 0)
  end

  after do
    Timecop.return
  end

  context "when fetching updated address id stats" do
    it "executes the use case and returns a hash of the the combines data set" do
      day_date = Time.now.strftime("%Y-%m-%d")
      expect(use_case.execute(day_date)).to eq("The bulk linking rake has been run. On 2024-12-22 1 groups of addresses were linked, 2 address ids were updated")
    end
  end
end
