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
      expect(Helper::Toggles).to be_enabled("test-enabled-feature")
    end

    it "feature test-disabled-feature is not active" do
      expect(Helper::Toggles).not_to be_enabled("test-disabled-feature")
    end

    context "when a block is passed" do
      block_executed = nil

      before do
        block_executed = false
        Helper::Toggles.enabled?("test-enabled-feature") { block_executed = true }
      end

      it "executes the block" do
        expect(block_executed).to be true
      end
    end
  end

  context "with an unknown feature toggle" do
    it "feature test-unknown-feature is not active" do
      expect(Helper::Toggles).not_to be_enabled("test-unknown-feature")
    end

    it "feature test-unknown-feature is active if given true default" do
      expect(Helper::Toggles).to be_enabled("test-unknown-feature", default: true)
    end

    context "when a block is passed" do
      block_executed = nil

      before do
        block_executed = false
        Helper::Toggles.enabled?("test-unknown-feature") { block_executed = true }
      end

      it "does not execute the block" do
        expect(block_executed).to be false
      end
    end
  end
end
