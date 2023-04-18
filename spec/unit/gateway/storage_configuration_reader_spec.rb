describe Gateway::StorageConfigurationReader do
  let(:instance_name) { "myinstance" }
  let(:expected_bucket_name) { "mybucket" }
  let(:expected_access_key) { "myaccesskey" }
  let(:expected_secret_access_key) { "mysecret" }

  before { allow(ENV).to receive(:[]).and_return(nil) }
  after { allow(ENV).to receive(:[]).and_return(nil) }

  context "when VCAP_SERVICES is present and we provide a GOV.UK PaaS S3 instance name" do
    subject(:storage_configuration_reader) { described_class.new(instance_name:) }

    before do
      allow(ENV).to receive(:[])
        .with("VCAP_SERVICES")
        .and_return(get_vcap_services_stub)
    end

    let(:config) { storage_configuration_reader.get_configuration }

    it "provides a config that gives access to a credentials object", aggregate_failures: true do
      credentials = config.credentials.credentials
      expect(credentials.access_key_id).to eq expected_access_key
      expect(credentials.secret_access_key).to eq expected_secret_access_key
    end

    it "the credentials extractor return a bucket name" do
      expect(config.bucket_name).to eq expected_bucket_name
    end
  end

  context "when VCAP_SERVICES is not present and we provide a GOV.UK PaaS S3 instance name" do
    subject(:storage_configuration_reader) { described_class.new(instance_name:) }

    it "we get back an exception" do
      expect { storage_configuration_reader.get_configuration }.to raise_error(
        "Local AWS credentials or VCAP_SERVICES not present",
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

  context "when VCAP_SERVICES is not present but AWS ECS credentials are and we provide an S3 bucket name" do
    subject(:storage_configuration_reader) { described_class.new(bucket_name: expected_bucket_name) }

    before do
      allow(ENV).to receive(:[]).with("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI").and_return("aws_credentials_uri")
      allow(ENV).to receive(:[]).with("AWS_EXECUTION_ENV").and_return("AWS_ECS_FARGATE")
    end

    let(:config) { storage_configuration_reader.get_configuration }

    it "passes back a configuration with ECS credentials that refers to the passed bucket name" do
      expect(config.bucket_name).to eq expected_bucket_name
      expect(config.credentials?).to be true
      expect(config.credentials).to be_an_instance_of Aws::ECSCredentials
    end
  end

  context "when VCAP_SERVICES is present and no GOV.UK PaaS S3 instance name is provided" do
    subject(:storage_configuration_reader) { described_class.new }

    before do
      allow(ENV).to receive(:[])
        .with("VCAP_SERVICE")
        .and_return(get_vcap_services_stub)
    end

    it "we get back an exception" do
      expect { storage_configuration_reader.get_configuration }.to raise_error(
        "Local AWS credentials or VCAP_SERVICES not present",
      )
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
        "Local AWS credentials or VCAP_SERVICES not present",
      )
    end
  end
end
