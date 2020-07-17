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
            fuel_heat_source: 1, fuel_price: "3.93", standing_charge: "88.00"
          },
          {
            fuel_heat_source: 9, fuel_price: "3.93", standing_charge: "88.00"
          },
          {
            fuel_heat_source: 2, fuel_price: "6.59", standing_charge: "58.00"
          },
          {
            fuel_heat_source: 3, fuel_price: "10.71", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 7, fuel_price: "6.59", standing_charge: "58.00"
          },
          {
            fuel_heat_source: 4, fuel_price: "4.35", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 74, fuel_price: "4.35", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 75, fuel_price: "4.88", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 71, fuel_price: "6.11", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 73, fuel_price: "6.11", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 76,
            fuel_price: "47.00",
            standing_charge: "0.00",
          },
          {
            fuel_heat_source: 11, fuel_price: "4.18", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 15, fuel_price: "4.14", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 12, fuel_price: "5.17", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 20, fuel_price: "4.65", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 22, fuel_price: "6.09", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 23, fuel_price: "5.51", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 21, fuel_price: "3.48", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 10, fuel_price: "4.53", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 30,
            fuel_price: "17.56",
            standing_charge: "80.00",
          },
          {
            fuel_heat_source: 32,
            fuel_price: "20.72",
            standing_charge: "11.00",
          },
          {
            fuel_heat_source: 31, fuel_price: "8.13", standing_charge: "0.00"
          },
          {
            fuel_heat_source: 34,
            fuel_price: "18.71",
            standing_charge: "8.00",
          },
          {
            fuel_heat_source: 33,
            fuel_price: "10.68",
            standing_charge: "0.00",
          },
          {
            fuel_heat_source: 38,
            fuel_price: "15.73",
            standing_charge: "32.00",
          },
          {
            fuel_heat_source: 40,
            fuel_price: "10.66",
            standing_charge: "0.00",
          },
          {
            fuel_heat_source: 35,
            fuel_price: "10.38",
            standing_charge: "21.00",
          },
          {
            fuel_heat_source: 36,
            fuel_price: "17.56",
            standing_charge: "0.00",
          },
          {
            fuel_heat_source: 47,
            fuel_price: "4.79",
            standing_charge: "88.00",
          },
          {
            fuel_heat_source: 48, fuel_price: "3.35", standing_charge: "0.00"
          },
        ]
      end
    end
  end
end
