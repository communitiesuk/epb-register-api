require "rspec"

describe "Gateway::StorageConfigurationReader" do
  INSTANCE_NAME = "myinstance".freeze
  EXPECTED_BUCKET_NAME = "mybucket".freeze
  EXPECTED_ACCESS_KEY = "myaccesskey".freeze
  EXPECTED_SECRET_ACCESS_KEY = "mysecret".freeze

  before { allow(ENV).to receive(:[]).and_return(nil) }

  context "when VCAP_SERVICES is present and we provide a GOV.UK PaaS S3 instance name" do
    before do
      @storage_configuration =
        Gateway::StorageConfigurationReader.new(instance_name: INSTANCE_NAME)
      allow(ENV).to receive(:[])
        .with("VCAP_SERVICES")
        .and_return(get_vcap_services_stub)
    end

    let(:credentials) { @storage_configuration.get_configuration }

    it "the credentials extractor return an access key ID" do
      expect(credentials.access_key_id).to eq EXPECTED_ACCESS_KEY
    end

    it "the credentials extractor return an secret access key" do
      expect(credentials.secret_access_key).to eq EXPECTED_SECRET_ACCESS_KEY
    end

    it "the credentials extractor return a bucket name" do
      expect(credentials.bucket_name).to eq EXPECTED_BUCKET_NAME
    end
  end

  context "when VCAP_SERVICES is not present and we provide a GOV.UK PaaS S3 instance name" do
    before do
      @storage_configuration =
        Gateway::StorageConfigurationReader.new(instance_name: INSTANCE_NAME)
    end

    it "we get back an exception" do
      expect { @storage_configuration.get_configuration }.to raise_error(
        "Local AWS credentials or VCAP_SERVICES not present",
      )
    end
  end

  context "when AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are present and we provide an S3 bucket name" do
    before do
      @storage_configuration =
        Gateway::StorageConfigurationReader.new(
          bucket_name: EXPECTED_BUCKET_NAME,
        )
      allow(ENV).to receive(:[])
        .with("AWS_ACCESS_KEY_ID")
        .and_return(EXPECTED_ACCESS_KEY)
      allow(ENV).to receive(:[])
        .with("AWS_SECRET_ACCESS_KEY")
        .and_return(EXPECTED_SECRET_ACCESS_KEY)
    end

    let(:credentials) { @storage_configuration.get_configuration }

    it "the credentials extractor return an access key ID" do
      expect(credentials.access_key_id).to eq EXPECTED_ACCESS_KEY
    end

    it "the credentials extractor return an secret access key" do
      expect(credentials.secret_access_key).to eq EXPECTED_SECRET_ACCESS_KEY
    end

    it "the credentials extractor return a bucket name" do
      expect(credentials.bucket_name).to eq EXPECTED_BUCKET_NAME
    end
  end

  context "when AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are not present and we provide an S3 bucket name" do
    before do
      @storage_configuration =
        Gateway::StorageConfigurationReader.new(
          bucket_name: EXPECTED_BUCKET_NAME,
        )
    end

    it "we get back an exception" do
      expect { @storage_configuration.get_configuration }.to raise_error(
        "Local AWS credentials or VCAP_SERVICES not present",
      )
    end
  end

  context "when VCAP_SERVICES is present and no GOV.UK PaaS S3 instance name is provided" do
    before do
      @storage_configuration = Gateway::StorageConfigurationReader.new
      allow(ENV).to receive(:[])
        .with("VCAP_SERVICE")
        .and_return(get_vcap_services_stub)
    end

    it "we get back an exception" do
      expect { @storage_configuration.get_configuration }.to raise_error(
        "Local AWS credentials or VCAP_SERVICES not present",
      )
    end
  end

  context "when AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are present and no S3 bucket name is provided" do
    before do
      @storage_configuration = Gateway::StorageConfigurationReader.new
      allow(ENV).to receive(:[])
        .with("AWS_ACCESS_KEY_ID")
        .and_return(EXPECTED_ACCESS_KEY)
      allow(ENV).to receive(:[])
        .with("AWS_SECRET_ACCESS_KEY")
        .and_return(EXPECTED_SECRET_ACCESS_KEY)
    end

    it "we get back an exception" do
      expect { @storage_configuration.get_configuration }.to raise_error(
        "Local AWS credentials or VCAP_SERVICES not present",
      )
    end
  end
end
