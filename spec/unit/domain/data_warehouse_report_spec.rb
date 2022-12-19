describe Domain::DataWarehouseReport do
  subject(:report) { described_class.new name: :my_report, data: 46, generated_at: "2022-12-16T17:21:45Z" }

  it "provides its name" do
    expect(report.name).to eq :my_report
  end

  it "provides its data" do
    expect(report.data).to eq 46
  end

  it "provides its generation time as a string" do
    expect(report.generated_at).to eq "2022-12-16T17:21:45Z"
  end

  it "can express itself as a hash" do
    expect(report.to_hash).to eq({ name: :my_report, data: 46, generated_at: "2022-12-16T17:21:45Z" })
  end
end
