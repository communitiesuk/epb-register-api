describe Gateway::StorageConfigurationReader do
  let(:expected_bucket_name) { "mybucket" }
  let(:expected_access_key) { "myaccesskey" }
  let(:expected_secret_access_key) { "mysecret" }

  before { allow(ENV).to receive(:[]).and_return(nil) }
  after { allow(ENV).to receive(:[]).and_return(nil) }

  context "when we provide do not provide S3 bucket name" do
    subject(:storage_configuration_reader) { described_class.new(bucket_name: nil) }

    it "we get back an exception" do
      expect { storage_configuration_reader.get_configuration }.to raise_error(
        "Local or AWS credentials not present",
      )
    end
  end

  context "when AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are present and we provide an S3 bucket name" do
    subject(:storage_configuration_reader) { described_class.new(bucket_name: expected_bucket_name) }

    before do
      allow(ENV).to receive(:[])
        .with("AWS_ACCESS_KEY_ID")
        .and_return(expected_access_key)
      allow(ENV).to receive(:[])
        .with("AWS_SECRET_ACCESS_KEY")
        .and_return(expected_secret_access_key)
    end

    let(:config) { storage_configuration_reader.get_configuration }

    it "provides a config that gives a credentials provider", aggregate_failures: true do
      credentials = config.credentials.credentials
      expect(credentials.access_key_id).to eq expected_access_key
      expect(credentials.secret_access_key).to eq expected_secret_access_key
    end

    it "the credentials extractor return a bucket name" do
      expect(config.bucket_name).to eq expected_bucket_name
    end
  end

  context "when AWS ECS credentials are and we provide an S3 bucket name" do
    subject(:storage_configuration_reader) { described_class.new(bucket_name: expected_bucket_name) }

    before do
      WebMock.enable!
      allow(ENV).to receive(:[]).with("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI").and_return("http://169.254.170.2")
      allow(ENV).to receive(:[]).with("AWS_EXECUTION_ENV").and_return("AWS_ECS_FARGATE")
      # stub the request using the ip address hard codes int the Aws SDK ecs_configuration.rb
      WebMock.stub_request(:get, "http://169.254.170.2").to_return(status: 200, body: resp)
    end

    after do
      WebMock.disable!
    end

    let(:resp) { <<~JSON.strip }
      {
        "RoleArn" : "arn:aws:iam::123456789012:role/BarFooRole",
        "AccessKeyId" : "akid",
        "SecretAccessKey" : "secret",
        "Token" : "session-token",
        "Expiration" : "#{expiration.strftime('%Y-%m-%dT%H:%M:%SZ')}"
      }
    JSON

    let(:expiration) { Time.now.utc + 3600 }
    let(:config) { storage_configuration_reader.get_configuration }

    it "passes back a configuration with ECS credentials that refers to the passed bucket name" do
      expect(config.bucket_name).to eq expected_bucket_name
      expect(config.credentials?).to be true
      expect(config.credentials).to be_an_instance_of Aws::ECSCredentials
    end
  end

  context "when AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are present and no S3 bucket name is provided" do
    subject(:storage_configuration_reader) { described_class.new }

    before do
      allow(ENV).to receive(:[])
        .with("AWS_ACCESS_KEY_ID")
        .and_return(expected_access_key)
      allow(ENV).to receive(:[])
        .with("AWS_SECRET_ACCESS_KEY")
        .and_return(expected_secret_access_key)
    end

    it "we get back an exception" do
      expect { storage_configuration_reader.get_configuration }.to raise_error(
        "Local or AWS credentials not present",
      )
    end
  end
end
