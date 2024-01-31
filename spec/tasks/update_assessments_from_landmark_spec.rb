describe "Update asssessments from landmark rake" do
  include RSpecRegisterApiServiceMixin
  let(:described_class) { get_task("oneoff:update_assessments_from_landmark") }
  let(:file_name) { "landmark_non_domestic_epcs_dates.csv" }

  let(:data) do
    file = "spec/fixtures/landmark_dates.csv"
    File.open(file)
  end

  before do
    WebMock.enable!
    WebMock.stub_request(:get, "https://slack.com/api/files.upload").to_return(status: 200, headers: {}, body: { ok: true }.to_json)
    allow($stdout).to receive(:puts)
    EnvironmentStub
      .all
      .with("LANDMARK_BUCKET", "test-bucket")
      .with("FILE_NAME", file_name)

    HttpStub.s3_get_object(file_name, data)
  end

  it "execs the rake" do
    expect { described_class.invoke }.not_to raise_error
  end

  it "prints the number of updated epcs" do
    expect { described_class.invoke }.not_to raise_error
  end
end
