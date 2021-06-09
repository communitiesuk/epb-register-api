describe "Gateway::MetOfficeGateway" do
  context "read degrees day data stored by the Met office " do
    let(:gateway) { instance_double("Gateway::MetOfficeGateway") }
    subject { Gateway::MetOfficeGateway.new }

    it "read the object" do
      expect { subject }.not_to raise_error
    end

    it "calls the method to read the data" do
      allow(gateway).to receive(:read_degrees_day_data).and_return([])
      expect(gateway.read_degrees_day_data).to eq([])
    end
  end
end
