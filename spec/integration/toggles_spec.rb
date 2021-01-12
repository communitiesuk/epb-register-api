describe "Integration::ToggleService" do
  before(:all) do
    TogglesStub.enable "test-enabled-feature": true,
                       "test-disabled-feature": false

    loader_enable_original "helper/toggles"
  end

  after(:all) do
    Helper::Toggles.shutdown!
    TogglesStub.disable

    loader_enable_override "helper/toggles"
  end

  context "with a known feature toggle" do
    it "feature test-enabled-feature is active" do
      expect(Helper::Toggles.enabled?("test-enabled-feature")).to eq(true)
    end

    it "feature test-disabled-feature is not active" do
      expect(Helper::Toggles.enabled?("test-disabled-feature")).to eq(false)
    end
  end

  context "with an unknown feature toggle" do
    it "feature test-unknown-feature is not active" do
      expect(Helper::Toggles.enabled?("test-unknown-feature")).to eq(false)
    end

    it "feature test-unknown-feature is active if given true default" do
      expect(Helper::Toggles.enabled?("test-disabled-feature", true)).to eq(true)
    end
  end
end
