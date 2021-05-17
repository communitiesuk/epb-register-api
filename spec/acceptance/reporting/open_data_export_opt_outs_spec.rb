describe "OpenDataExportOptOuts" do
  subject(:task) { get_task("open_data_export_opt_out") }
  context "We invoke the Open Data Communities export Rake directly" do
    before do
      EnvironmentStub.all
      HttpStub.s3_put_csv(
        "open_data_export_opt_outs_#{DateTime.now.strftime('%F')}.csv",
      )
    end

    it "initialises the storage gateway with task parameters" do
      task.invoke
      expect(WebMock).to have_requested(
        :put,
        "#{HttpStub::S3_BUCKET_URI}open_data_export_opt_outs_#{DateTime.now.strftime('%F')}.csv",
      ).with(headers: { "Host" => "s3.eu-west-2.amazonaws.com" })
    end
  end

  context "when bucket_name or instance_name is not provided to the export task" do
    let(:bucket_name) { "bucket_name" }
    let(:instance_name) { "epb-s3-service" }

    let(:storage_gateway) { instance_double(Gateway::StorageGateway) }

    let(:export_usecase) { instance_double(UseCase::ExportOpenDataOptOuts) }

    let(:export) do
      [
        {
          assessment_id:
            "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
        },
        {
          assessment_id:
            "55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4",
        },
      ]
    end

    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("instance_name").and_return(instance_name)
      allow(ENV).to receive(:[]).with("bucket_name").and_return(bucket_name)

      # Prevents logging during tests
      allow(STDOUT).to receive(:puts)

      # Mocks all dependencies created directly in the task
      allow(ApiFactory).to receive(:export_opt_out_use_case).and_return(
        export_usecase,
      )
      allow(ApiFactory).to receive(:storage_gateway).and_return(storage_gateway)

      # Define mock expectations
      allow(export_usecase).to receive(:execute).and_return(export)
      allow(storage_gateway).to receive(:write_file)
    end

    it "fails to run with the relevant message" do
      expect { task.invoke }.not_to raise_error
    end
  end
end
