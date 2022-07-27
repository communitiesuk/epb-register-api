describe UseCase::DeleteGeolocationTables do
  let(:use_case) { described_class.new(gateway) }
  let(:gateway) { instance_double(Gateway::PostcodeGeolocationGateway) }

  before do
    allow(gateway).to receive(:clean_up)
    allow($stdout).to receive(:puts)
  end

  context "when calling the use case to delete the tables" do
    it "executes without error" do
      expect { use_case.execute }.not_to raise_error
    end

    it "calls the gateway" do
      use_case.execute
      expect(gateway).to have_received(:clean_up).exactly(1).times
    end
  end
end
