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
            fuel_heat_source: 1,
            fuel_price: "3.97",
            standing_charge: "90.0",
          },
          {
            fuel_heat_source: 9,
            fuel_price: "3.97",
            standing_charge: "90.0",
          },
          {
            fuel_heat_source: 2,
            fuel_price: "6.74",
            standing_charge: "59.0",
          },
          {
            fuel_heat_source: 3,
            fuel_price: "10.86",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 7,
            fuel_price: "6.74",
            standing_charge: "59.0",
          },
          { fuel_heat_source: 4, fuel_price: "4.6", standing_charge: "0.0" },
          {
            fuel_heat_source: 74,
            fuel_price: "4.6",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 75,
            fuel_price: "5.16",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 71,
            fuel_price: "6.46",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 73,
            fuel_price: "6.46",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 76,
            fuel_price: "47.0",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 11,
            fuel_price: "4.22",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 15,
            fuel_price: "4.13",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 12,
            fuel_price: "5.14",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 20,
            fuel_price: "4.65",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 22,
            fuel_price: "6.09",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 23,
            fuel_price: "5.51",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 21,
            fuel_price: "3.48",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 10,
            fuel_price: "4.56",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 30,
            fuel_price: "18.27",
            standing_charge: "84.0",
          },
          {
            fuel_heat_source: 32,
            fuel_price: "21.54",
            standing_charge: "6.0",
          },
          {
            fuel_heat_source: 31,
            fuel_price: "8.44",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 34,
            fuel_price: "19.08",
            standing_charge: "4.0",
          },
          {
            fuel_heat_source: 33,
            fuel_price: "10.89",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 38,
            fuel_price: "16.11",
            standing_charge: "27.0",
          },
          {
            fuel_heat_source: 40,
            fuel_price: "10.93",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 35,
            fuel_price: "10.75",
            standing_charge: "17.0",
          },
          {
            fuel_heat_source: 36,
            fuel_price: "18.27",
            standing_charge: "0.0",
          },
          {
            fuel_heat_source: 47,
            fuel_price: "4.84",
            standing_charge: "90.0",
          },
          {
            fuel_heat_source: 48,
            fuel_price: "3.39",
            standing_charge: "0.0",
          },
        ]
      end
    end
  end
end
