describe UseCase::AddScheme do
  let(:schemes_gateway) { SchemesGatewaySpy.new }
  let!(:response) { described_class.new(schemes_gateway).execute("name") }

  context "when adding a scheme" do
    it "checks if add was called" do
      expect(schemes_gateway.add_was_called?).to be true
    end
  end
end
