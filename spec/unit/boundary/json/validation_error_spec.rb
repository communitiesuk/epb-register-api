describe Boundary::Json::ValidationError do
  context "when failed properties are passed to the error on initialisation" do
    it "can return the failed properties passed" do
      error = described_class.new("I am a message", failed_properties: %w[town postcode])
      expect(error.failed_properties).to eq %w[town postcode]
    end
  end
end
