describe "OpenDataExportNotForPublication" do
  subject(:task) { get_task("open_data_export_not_for_publication") }

  after { WebMock.disable! }

  let(:storage_gateway) { instance_double(Gateway::StorageGateway) }
  let(:export_usecase) { instance_double(UseCase::ExportOpenDataNotForPublication) }
  let(:incorrect_bucket_name) { "bucket_name" }
  let(:incorrect_instance_name) { "epb-s3-service" }

  let(:export) do
    [
      {
        assessment_id:
          "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
        type_of_assessment: "RdSAP",
        address_line1: "1 Some Street",
        address_line2: "",
        address_line3: "",
      },
      {
        assessment_id:
          "55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4",
        type_of_assessment: "CEPC",
        address_line1: "1 Some Street",
        address_line2: "",
        address_line3: "",
      },
    ]
  end

  let(:csv_data) do
    "ASSESSMENT_ID,TYPE_OF_ASSESSMENT,ADDRESS_LINE1,ADDRESS_LINE2,ADDRESS_LINE3\n" \
      "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a,RdSAP,1 Some Street,\"\",\"\"\n" \
      "55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4,CEPC,1 Some Street,\"\",\"\"\n"
  end

  context "when correct bucket_name or instance_name are provided" do
    before do
      EnvironmentStub.all
      allow(ApiFactory).to receive(:export_not_for_publication_use_case).and_return(
        export_usecase,
      )
      allow(ApiFactory).to receive(:storage_gateway).and_return(storage_gateway)

      # Define mock expectations
      allow(export_usecase).to receive(:execute).and_return(export)
      HttpStub.s3_put_csv(
        "open_data_export_not_for_publication_#{DateTime.now.strftime('%F')}.csv",
      )
    end

    it "raises an error when type of export is not provided" do
      expected_message =
        "A required argument is missing: type_of_export. You  must specify 'for_odc' or 'not_for_odc'"

      expect { task.invoke }.to output(/#{expected_message}/).to_stderr
    end

    it "raises an error when a wrong type of export is provided" do
      expected_message =
        "A required argument is missing: type_of_export. You  must specify 'for_odc' or 'not_for_odc'"

      expect { task.invoke("for_dean") }.to output(/#{expected_message}/)
        .to_stderr
    end

    it "raises an error if there is no data" do
      expected_message = "No data provided for export"
      allow(export_usecase).to receive(:execute).and_return([])

      expect { task.invoke("for_odc") }.to output(/#{expected_message}/).to_stderr
    end

    it "doesn't prefix csv filename with `test/` so it's stored in the main directory in the S3 bucket" do
      allow(Gateway::StorageGateway).to receive(:new).and_return(
        storage_gateway,
      )
      allow(storage_gateway).to receive(:write_file)

      task.invoke("for_odc")

      expect(storage_gateway).to have_received(:write_file).with(
        "open_data_export_not_for_publication_#{DateTime.now.strftime('%F')}.csv",
        csv_data,
      )
    end

    it "sends the converted csv to the S3 bucket " do
      task.invoke("for_odc")
      expect(WebMock).to have_requested(
        :put,
        "#{HttpStub::S3_BUCKET_URI}open_data_export_not_for_publication_#{DateTime.now.strftime('%F')}.csv",
      ).with(
        body: /ASSESSMENT_ID,TYPE_OF_ASSESSMENT,ADDRESS_LINE1,ADDRESS_LINE2,ADDRESS_LINE3/,
        headers: {
          "Host" => "s3.eu-west-2.amazonaws.com",
        },
      )

      expect(WebMock).to have_requested(
        :put,
        "#{HttpStub::S3_BUCKET_URI}open_data_export_not_for_publication_#{DateTime.now.strftime('%F')}.csv",
      ).with(
        body: /4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a/,
      )
    end

    context "when running a test export" do
      it "prefixes the csv filename with `test/` so it's stored in a separate folder in the S3 bucket" do
        HttpStub.s3_put_csv(
          "test/open_data_export_not_for_publication_#{DateTime.now.strftime('%F')}.csv",
        )
        allow(Gateway::StorageGateway).to receive(:new).and_return(
          storage_gateway,
        )
        allow(storage_gateway).to receive(:write_file)

        task.invoke("not_for_odc")

        expect(storage_gateway).to have_received(:write_file).with(
          "test/open_data_export_not_for_publication_#{DateTime.now.strftime('%F')}.csv",
          csv_data,
        )
      end
    end
  end

  context "when bucket_name or instance_name is not provided to the export task" do
    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[])
        .with("INSTANCE_NAME")
        .and_return(incorrect_instance_name)
      allow(ENV).to receive(:[])
        .with("BUCKET_NAME")
        .and_return(incorrect_bucket_name)

      # Prevents logging during tests
      allow($stdout).to receive(:puts)

      # Mocks all dependencies created directly in the task
      allow(ApiFactory).to receive(:export_not_for_publication_use_case).and_return(
        export_usecase,
      )
      allow(ApiFactory).to receive(:storage_gateway).and_return(storage_gateway)

      # Define mock expectations
      allow(export_usecase).to receive(:execute).and_return(export)
      allow(storage_gateway).to receive(:write_file)
    end

    it "fails to run with the relevant error type" do
      expect { task.invoke("for_odc") }.to raise_error(
        Gateway::StorageConfigurationReader::IllegalCallException,
      )
    end
  end
end
