describe Domain::DataWarehouseReportCollection do
  context "when creating an empty collection with empty arguments" do
    let(:collection) { described_class.new [] }

    it "converts to an empty array" do
      expect(collection.to_a).to eq []
    end
  end

  context "when creating a collection of reports" do
    let(:collection) { described_class.new(*reports) }

    let(:reports) do
      [
        Domain::DataWarehouseReport.new(name: :my_report_1, data: 34, generated_at: "2022-12-18T09:03:45Z"),
        Domain::DataWarehouseReport.new(name: :my_report_2, data: 45, generated_at: "2022-12-18T09:03:47Z"),
      ]
    end

    it "converts to array containing the reports" do
      expect(collection.to_a).to eq reports
    end

    it "is not incomplete" do
      expect(collection).not_to be_incomplete
    end
  end

  context "when creating an incomplete collection of reports" do
    let(:collection) { described_class.new(*reports, incomplete: true) }

    let(:reports) do
      [
        Domain::DataWarehouseReport.new(name: :my_report_2, data: 45, generated_at: "2022-12-18T09:03:47Z"),
      ]
    end

    it "is incomplete" do
      expect(collection).to be_incomplete
    end
  end
end
