describe Helper::Platform do
  context "when the app is being run within GOV.UK PaaS" do
    before { stub_const("ENV", { "VCAP_SERVICES" => "{}" }) }

    it "reports as being is PaaS" do
      expect(described_class.is_paas?).to be true
    end
  end

  context "when the app is not being run within GOV.UK PaaS" do
    it "reports as not being is PaaS" do
      expect(described_class.is_paas?).to be false
    end
  end
end
