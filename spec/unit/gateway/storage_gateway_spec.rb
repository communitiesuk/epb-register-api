shared_context "when calling the storage gateway" do
  def stub_file_response(client)
    client.stub_responses(
      :get_object,
      lambda do |context|
        if context.params[:key] == "my-file" &&
          context.params[:bucket] == "my-bucket"
          { body: "Hello!" }
        else
          "NoSuchKey"
        end
      end,
    )
  end
end

describe Gateway::StorageGateway do
  include_context "when calling the storage gateway"
  context "when storage is initialised" do
    subject(:storage_gateway) do
      described_class.new(
        storage_config:
          Gateway::StorageConfiguration.new(
            access_key_id: "",
            secret_access_key: "",
            bucket_name: "my-bucket",
          ),
        stub_responses: true,
      )
    end

    it "retrieves an existing file" do
      stub_file_response(storage_gateway.client)
      expect(storage_gateway.get_file_io("my-file").string).to eq "Hello!"
    end

    it "fails when the file is not existing" do
      stub_file_response(storage_gateway.client)
      expect {
        storage_gateway.get_file_io("fake_name")
      }.to raise_error Aws::S3::Errors::NoSuchKey
    end
  end
end
