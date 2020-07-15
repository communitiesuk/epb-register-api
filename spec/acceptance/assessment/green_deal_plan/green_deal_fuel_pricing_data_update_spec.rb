describe "Acceptance::Assessment::GreenDealPlan:UpdateFuelCostData" do
  context "when there is no fuel data in the database" do
    describe "running the fuel price data update task" do
      before do
        @fuel_price_mock = GreenDealFuelDataMock.new
        Rake::Task["green_deal_update_fuel_data"].invoke
      end

      after { @fuel_price_mock.disable }

      it "populates the database with the expected values" do
        fuel_price_data =
          ActiveRecord::Base
            .connection.execute "SELECT * FROM green_deal_fuel_price_data"

        fuel_price_data =
          fuel_price_data.map do |row|
            row.slice "fuel_heat_source", "standing_charge", "fuel_price"
          end

        hashed_entries =
          JSON.parse fuel_price_data.entries.to_json, symbolize_names: true

        expect(hashed_entries).to eq [
          {
            fuel_heat_source: 1, standing_charge: "91.00", fuel_price: "3.95"
          },
          {
            fuel_heat_source: 4, standing_charge: "0.00", fuel_price: "4.61"
          },
          {
            fuel_heat_source: 21, standing_charge: "0.00", fuel_price: "3.57"
          },
          {
            fuel_heat_source: 40,
            standing_charge: "0.00",
            fuel_price: "11.20",
          },
        ]
      end
    end
  end
end
