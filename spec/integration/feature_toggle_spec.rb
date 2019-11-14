require "api"

describe "feature toggles" do
  context "checking states" do
    it 'is enabled for feature_toggle_check_positive' do
      expect($unleash.is_enabled?("feature_toggle_check_positive")).to eq(true)
    end

    it 'is disabled for feature_toggle_check_negative' do
      expect($unleash.is_enabled?("feature_toggle_check_negative")).to eq(false)
    end
  end
end