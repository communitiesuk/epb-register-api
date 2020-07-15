describe Helper::GreenDealSavingsCalculator do
  context "known working example" do
    let(:fuel_saving_data) do
      [
        {
          fuel_price: "18.27",
          standing_charge: "84",
          fuel_saving: 23_253,
          standing_charge_fraction: "0",
        },
        {
          fuel_price: "8.44",
          standing_charge: "0",
          fuel_saving: -15_561,
          standing_charge_fraction: "0",
        },
        {
          fuel_price: "21.54",
          standing_charge: "6",
          fuel_saving: -6331,
          standing_charge_fraction: "-0.9",
        },
      ]
    end

    describe "calculating the annual fuel savings" do
      let(:calculated_savings) { described_class.calculate fuel_saving_data }

      it "produces the known figure" do
        expect(calculated_savings).to eq 1566
      end
    end
  end
end
