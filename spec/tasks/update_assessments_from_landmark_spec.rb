describe "Update assessments from landmark rake" do
  include RSpecRegisterApiServiceMixin
  let(:described_class) { get_task("oneoff:update_assessments_from_landmark") }
  let(:file_name) { "landmark_non_domestic_epcs_dates.csv" }

  let(:storage_gateway) { instance_double(Gateway::StorageGateway) }
  let(:use_case) do
    instance_double(UseCase::UpdateAssessmentsFromLandmark)
  end

  before do
    allow($stdout).to receive(:puts)
    EnvironmentStub
      .all
      .with("LANDMARK_DATA_BUCKET_NAME", "test-bucket")
      .with("FILE_NAME", file_name)

    allow(ApiFactory).to receive_messages(update_assessments_from_landmark: use_case, storage_gateway:)
    allow(use_case).to receive(:execute).and_return(5)
  end

  it "execs the rake" do
    expect { described_class.invoke }.not_to raise_error
  end

  it "prints the number of updated EPCs" do
    expect { described_class.invoke }.to output(
      /5 assessments have been updated/,
    ).to_stdout
  end
end
