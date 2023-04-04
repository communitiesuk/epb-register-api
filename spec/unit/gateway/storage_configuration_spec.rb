describe Gateway::StorageConfiguration do
  context "when a storage configuration has credentials" do
    subject(:config) { described_class.new access_key_id:, secret_access_key:, bucket_name: }

    let(:access_key_id) { "ACCESSKEYID" }
    let(:secret_access_key) { "SECRETACCESSKEY" }
    let(:bucket_name) { "BUCKETNAME" }

    it "has the provided access key ID" do
      expect(config.access_key_id).to eq access_key_id
    end

    it "has the provided secret access key" do
      expect(config.secret_access_key).to eq secret_access_key
    end

    it "has the expected bucket name" do
      expect(config.bucket_name).to eq bucket_name
    end

    it "has the default region" do
      expect(config.region_name).to eq "eu-west-2"
    end

    it "has credentials" do
      expect(config.credentials?).to be true
    end
  end

  context "when a storage configuration does not have credentials" do
    subject(:config) { described_class.new bucket_name:, region_name: }

    let(:bucket_name) { "BUCKETNAME" }
    let(:region_name) { "eu-west-1" }

    it "has the provided bucket name" do
      expect(config.bucket_name).to eq bucket_name
    end

    it "has the passed-in region name" do
      expect(config.region_name).to eq region_name
    end

    it "does not have credentials" do
      expect(config.credentials?).to be false
    end
  end
end
