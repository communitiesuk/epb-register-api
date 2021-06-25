describe "JsonExport" do
  subject(:task) { get_task("json_export") }

  context "when the export task runs with all needed parameters" do
    let(:storage_gateway) { instance_double(Gateway::StorageGateway) }
    let(:export_usecase) do
      instance_double(UseCase::ExportAssessmentAttributes)
    end

    let(:start_date) { "2021-05-01" }
    let(:bucket_name) { "bucket_name" }
    let(:instance_name) { "epb-s3-service" }
    let(:export) do
      [
        { assessment_id: "001", data: { "attribute": "export 001" } },
        { assessment_id: "002", data: { "attribute": "export 002" } },
      ]
    end

    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("start_date").and_return(start_date)
      allow(ENV).to receive(:[]).with("instance_name").and_return(instance_name)
      allow(ENV).to receive(:[]).with("bucket_name").and_return(bucket_name)

      # Prevents logging during tests
      allow(STDOUT).to receive(:puts)

      # Mocks all dependencies created directly in the task
      allow(ApiFactory).to receive(:assessments_export_use_case).and_return(
        export_usecase,
      )
      allow(ApiFactory).to receive(:storage_gateway).and_return(storage_gateway)

      # Define mock expectations
      allow(export_usecase).to receive(:execute).and_return(export)
      allow(storage_gateway).to receive(:write_file)
    end

    it "initialises the storage gateway with task parameters" do
      expect(ApiFactory).to receive(:storage_gateway).with(
        bucket_name: bucket_name,
        instance_name: instance_name,
      )
      expect { task.invoke }.not_to raise_error
    end

    it "calls the export use_case with the start_date parameter" do
      expect(export_usecase).to receive(:execute).with(start_date)
      expect { task.invoke }.not_to raise_error
    end

    it "calls the storage gateway with the data received from the export use case" do
      expect(storage_gateway).to receive(:write_file).with(
        "export/001.json",
        "{\"attribute\":\"export 001\"}",
      )
      expect(storage_gateway).to receive(:write_file).with(
        "export/002.json",
        "{\"attribute\":\"export 002\"}",
      )
      expect { task.invoke }.not_to raise_error
    end
  end

  context "when start_date is not provided to the export task" do
    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[])
        .with("instance_name")
        .and_return("epb-s3-bucket")
    end

    it "fails to run with the relevant message" do
      expected_message = "A required argument is missing: start_date"
      expect { task.invoke }.to raise_error(Boundary::ArgumentMissing)
        .with_message(expected_message)
    end
  end

  context "when bucket_name or instance_name is not provided to the export task" do
    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("start_date").and_return("2021-05-01")
    end

    it "fails to run with the relevant message" do
      expected_message =
        "A required argument is missing: bucket_name or instance_name"
      expect { task.invoke }.to raise_error(Boundary::ArgumentMissing)
        .with_message(expected_message)
    end
  end
end
