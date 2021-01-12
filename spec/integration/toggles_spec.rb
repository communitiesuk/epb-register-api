xdescribe "Integration::ToggleService" do
  context "when the AssessorService is instantiated with Toggles" do
    let(:service) { RegisterApiService.new(TogglesStub.new).helpers }

    it "feature a is active" do
      expect(service.toggles.state("a")).to eq(true)
    end

    it "feature b is not active" do
      expect(service.toggles.state("b")).to eq(false)
    end
  end
end
