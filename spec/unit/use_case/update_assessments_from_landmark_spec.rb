describe UseCase::UpdateAssessmentsFromLandmark do
  include RSpecRegisterApiServiceMixin
  subject(:use_case) do
    described_class.new(assessments_gateway:, storage_gateway:)
  end

  let(:assessments_gateway) { instance_double(Gateway::AssessmentsGateway) }
  let(:storage_gateway) { instance_double(Gateway::StorageGateway) }

  let(:file_io) do
    file = "spec/fixtures/landmark_dates.csv"
    File.open(file)
  end

  before do
    allow(assessments_gateway).to receive(:update_created_at_from_landmark?).and_return(true)
    allow(storage_gateway).to receive(:get_file_io).and_return(file_io)
  end

  describe "#execute" do
    it "does not raise an error" do
      expect { use_case.execute(file_name: "test_bucket") }.not_to raise_error
    end

    it "sends all rows to gateway" do
      use_case.execute(file_name: "test_bucket")
      expect(assessments_gateway).to have_received(:update_created_at_from_landmark?).exactly(5).times
    end

    it "returns the number of rows updated" do
      expect(use_case.execute(file_name: "test_bucket")).to be 5
    end

    it "sends data for each row to the gateway to be saved" do
      use_case.execute(file_name: "test_bucket")
      expect(assessments_gateway).to have_received(:update_created_at_from_landmark?).with("0000-0000-0000-0000-0000", "2007-04-20 20:13:19").exactly(1).times
      expect(assessments_gateway).to have_received(:update_created_at_from_landmark?).with("0000-0000-0000-0000-0004", "2007-04-20 20:13:40").exactly(1).times
    end

    context "when one of the rows is not updated" do
      it "returns the number of rows updated as 4" do
        allow(assessments_gateway).to receive(:update_created_at_from_landmark?).with("0000-0000-0000-0000-0002", "2007-04-20 20:13:30").and_return(false)
        expect(use_case.execute(file_name: "test_bucket")).to be 4
      end
    end
  end
end
