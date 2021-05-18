describe "OpenDataExportOptOuts" do
  subject(:task) { get_task("open_data_export_opt_out") }

  after { WebMock.disable! }
  let(:storage_gateway) { instance_double(Gateway::StorageGateway) }
  let(:export_usecase) { instance_double(UseCase::ExportOpenDataOptOuts) }
  let(:bucket_name) { "bucket_name" }
  let(:instance_name) { "epb-s3-service" }

  let(:export) do
    [
      {
        assessment_id:
          "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
        type_of_assessment: "CEPC",
      },
      {
        assessment_id:
          "55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4",
        type_of_assessment: "CEPC",
      },
    ]
  end

  context "Invoke the export rake with mocked data" do
    before do
      EnvironmentStub.all.with("DATE_FROM", "2021-03-29")
      allow(ApiFactory).to receive(:export_opt_out_use_case).and_return(
        export_usecase,
      )
      allow(ApiFactory).to receive(:storage_gateway).and_return(storage_gateway)

      # Define mock expectations
      allow(export_usecase).to receive(:execute).and_return(export)
      HttpStub.s3_put_csv(
        "open_data_export_opt_outs_#{DateTime.now.strftime('%F')}.csv",
      )
    end

    it "makes an s3 PUT request of the correct /csv" do
      task.invoke
      expect(WebMock).to have_requested(
        :put,
        "#{HttpStub::S3_BUCKET_URI}open_data_export_opt_outs_#{DateTime.now.strftime('%F')}.csv",
      ).with(
        body: /ASSESSMENT_ID,TYPE_OF_ASSESSMENT/,
        headers: {
          "Host" => "s3.eu-west-2.amazonaws.com",
        },
      )

      expect(WebMock).to have_requested(
        :put,
        "#{HttpStub::S3_BUCKET_URI}open_data_export_opt_outs_#{DateTime.now.strftime('%F')}.csv",
      ).with(
        body: /4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a/,
      )
    end
  end

  context "We invoke the export Rake with no mocked data" do
    before { EnvironmentStub.all.with("DATE_FROM", "2021-03-29") }

    it "returns a no data to export error" do
      expect { task.invoke }.to output(/No data provided for export/).to_stderr
    end
  end

  context "when bucket_name or instance_name is not provided to the export task" do
    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("INSTANCE_NAME").and_return(instance_name)
      allow(ENV).to receive(:[]).with("BUCKET_NAME").and_return(bucket_name)
      allow(ENV).to receive(:[]).with("DATE_FROM").and_return("2020-012-01")

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

    it "fails to run with the relevant error type" do
      expect { task.invoke }.to raise_error(
        Gateway::StorageConfigurationReader::IllegalCallException,
      )
    end
  end
end
