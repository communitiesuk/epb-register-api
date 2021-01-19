require 'rspec'

describe 'StorageCredentialsExtractor' do

  INSTANCE_NAME = 'myinstance'
  EXPECTED_BUCKET_NAME = 'mybucket'
  EXPECTED_ACCESS_KEY = 'myaccesskey'
  EXPECTED_SECRET_ACCESS_KEY = 'mysecret'

  before do
    @storage_configuration = Gateway::StorageConfigurationReader.new
  end

  context 'when VCAP_SERVICES is present and we read PaaS credentials' do
    before do
      allow(ENV).to receive(:[]).with('VCAP_SERVICES').and_return(get_vcap_services)
    end

    let(:credentials) { @storage_configuration.get_paas_configuration(INSTANCE_NAME) }

    it 'the credentials extractor return an access key ID' do
      expect(credentials.access_key_id).to eq EXPECTED_ACCESS_KEY
    end

    it 'the credentials extractor return an secret access key' do
      expect(credentials.secret_access_key).to eq EXPECTED_SECRET_ACCESS_KEY
    end

    it 'the credentials extractor return a bucket name' do
      expect(credentials.bucket_name).to eq EXPECTED_BUCKET_NAME
    end
  end

  context 'when VCAP_SERVICES is not present and we read PaaS credentials' do
    before do
      allow(ENV).to receive(:[]).with('VCAP_SERVICES').and_return(nil)
    end

    it 'we get back an exception' do
      expect { @storage_configuration.get_paas_configuration(INSTANCE_NAME) }.to raise_error("No VCAP_SERVICES environment variable present")
    end
  end

  context 'when AWS_ACCESS_KEY_ID AND AWS_SECRET_ACCESS_KEY are present and we read local credentials' do
    before do
      allow(ENV).to receive(:[]).with('AWS_ACCESS_KEY_ID').and_return(EXPECTED_ACCESS_KEY)
      allow(ENV).to receive(:[]).with('AWS_SECRET_ACCESS_KEY').and_return(EXPECTED_SECRET_ACCESS_KEY)
    end

    let(:credentials) { @storage_configuration.get_local_configuration(EXPECTED_BUCKET_NAME) }

    it 'the credentials extractor return an access key ID' do
      expect(credentials.access_key_id).to eq EXPECTED_ACCESS_KEY
    end

    it 'the credentials extractor return an secret access key' do
      expect(credentials.secret_access_key).to eq EXPECTED_SECRET_ACCESS_KEY
    end

    it 'the credentials extractor return a bucket name' do
      expect(credentials.bucket_name).to eq EXPECTED_BUCKET_NAME
    end
  end

  context 'when AWS_ACCESS_KEY_ID AND AWS_SECRET_ACCESS_KEY are not present and we read local credentials' do
    before do
      allow(ENV).to receive(:[]).with('AWS_ACCESS_KEY_ID').and_return(nil)
      allow(ENV).to receive(:[]).with('AWS_SECRET_ACCESS_KEY').and_return(nil)
    end

    it 'we get back an exception' do
      expect { @storage_configuration.get_local_configuration(EXPECTED_BUCKET_NAME) }.to raise_error('No AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables present')
    end
  end
end

def get_vcap_services
  '{
    "aws-s3-bucket": [
      {
        "binding_name": null,
        "credentials": {
          "aws_access_key_id": "myaccesskey",
          "aws_region": "eu-west-2",
          "aws_secret_access_key": "mysecret",
          "bucket_name": "mybucket",
          "deploy_env": ""
        },
        "instance_name": "myinstance",
        "label": "aws-s3-bucket",
        "name": "myinstance",
        "plan": "default",
        "provider": null,
        "syslog_drain_url": null,
        "tags": [
          "s3"
        ],
        "volume_mounts": []
      }
    ]
  }'
end
