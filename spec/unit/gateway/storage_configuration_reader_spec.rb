describe Gateway::StorageConfigurationReader do
  let(:instance_name) { "myinstance" }
  let(:expected_bucket_name) { "mybucket" }
  let(:expected_access_key) { "myaccesskey" }
  let(:expected_secret_access_key) { "mysecret" }

  before { allow(ENV).to receive(:[]).and_return(nil) }

  context "when VCAP_SERVICES is present and we provide a GOV.UK PaaS S3 instance name" do
    subject(:storage_configuration) { described_class.new(instance_name: instance_name) }

    before do
      allow(ENV).to receive(:[])
        .with("VCAP_SERVICES")
        .and_return(get_vcap_services_stub)
    end

    let(:credentials) { storage_configuration.get_configuration }

    it "the credentials extractor return an access key ID" do
      expect(credentials.access_key_id).to eq expected_access_key
    end

    it "the credentials extractor return an secret access key" do
      expect(credentials.secret_access_key).to eq expected_secret_access_key
    end

    it "the credentials extractor return a bucket name" do
      expect(credentials.bucket_name).to eq expected_bucket_name
    end
  end

  context "when VCAP_SERVICES is not present and we provide a GOV.UK PaaS S3 instance name" do
    subject(:storage_configuration) { Gateway::StorageConfigurationReader.new(instance_name: instance_name) }

    it "we get back an exception" do
      expect { storage_configuration.get_configuration }.to raise_error(
        "Local AWS credentials or VCAP_SERVICES not present",
      )
    end
  end

  context "when AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are present and we provide an S3 bucket name" do
    subject(:storage_configuration) { Gateway::StorageConfigurationReader.new(bucket_name: expected_bucket_name) }

    before do
      allow(ENV).to receive(:[])
        .with("AWS_ACCESS_KEY_ID")
        .and_return(expected_access_key)
      allow(ENV).to receive(:[])
        .with("AWS_SECRET_ACCESS_KEY")
        .and_return(expected_secret_access_key)
    end

    let(:credentials) { storage_configuration.get_configuration }

    it "the credentials extractor return an access key ID" do
      expect(credentials.access_key_id).to eq expected_access_key
    end

    it "the credentials extractor return an secret access key" do
      expect(credentials.secret_access_key).to eq expected_secret_access_key
    end

    it "the credentials extractor return a bucket name" do
      expect(credentials.bucket_name).to eq expected_bucket_name
    end
  end

  context "when AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are not present and we provide an S3 bucket name" do
    subject(:storage_configuration) { Gateway::StorageConfigurationReader.new(bucket_name: expected_bucket_name) }

    it "we get back an exception" do
      expect { storage_configuration.get_configuration }.to raise_error(
        "Local AWS credentials or VCAP_SERVICES not present",
      )
    end
  end

  context "when VCAP_SERVICES is present and no GOV.UK PaaS S3 instance name is provided" do
    subject(:storage_configuration) { Gateway::StorageConfigurationReader.new }

    before do
      allow(ENV).to receive(:[])
        .with("VCAP_SERVICE")
        .and_return(get_vcap_services_stub)
    end

    it "we get back an exception" do
      expect { storage_configuration.get_configuration }.to raise_error(
        "Local AWS credentials or VCAP_SERVICES not present",
      )
    end
  end

  context "when AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are present and no S3 bucket name is provided" do
    subject(:storage_configuration) { Gateway::StorageConfigurationReader.new }

    before do
      allow(ENV).to receive(:[])
        .with("AWS_ACCESS_KEY_ID")
        .and_return(expected_access_key)
      allow(ENV).to receive(:[])
        .with("AWS_SECRET_ACCESS_KEY")
        .and_return(expected_secret_access_key)
    end

    it "we get back an exception" do
      expect { storage_configuration.get_configuration }.to raise_error(
        "Local AWS credentials or VCAP_SERVICES not present",
      )
    end
  end
end
