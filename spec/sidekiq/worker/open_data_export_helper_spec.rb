describe Worker::OpenDataExportHelper do
  describe "#get_last_months_methods" do
    before do
      Timecop.freeze(2022, 9, 1, 0, 0, 0)
    end

    after do
      Timecop.return
    end

    it "returns the correct dates" do
      expect(described_class.get_last_months_dates).to be_a(Hash)
      expect(described_class.get_last_months_dates[:start_date]).to eq "2022-08-01"
      expect(described_class.get_last_months_dates[:end_date]).to eq "2022-09-01"
    end
  end
end
