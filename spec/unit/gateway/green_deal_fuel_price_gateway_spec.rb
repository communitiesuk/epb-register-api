describe Gateway::GreenDealFuelPriceGateway do
  let(:gateway) { described_class.new }

  describe "#bulk_insert" do
    let(:price_data) do
      ["1,1,90,3.97,2019/Dec/03 12:12",
       "1,9,90,3.97,2019/Dec/03 12:12",
       "1,1,95,3.74,2022/Jun/30 14:30",
       "1,9,95,3.74,2022/Jun/30 14:30"]
    end

    before do
      gateway.bulk_insert(price_data)
    end

    it "has saved the data into the green_deal_fuel_price_data table" do
      result = ActiveRecord::Base.connection.exec_query("SELECT * FROM green_deal_fuel_price_data")
      expect(result.length).to eq 4
      expect(result[0]["fuel_heat_source"]).to eq(1)
      expect(result[0]["standing_charge"].to_s).to eq("90.0")
      expect(result[0]["fuel_price"].to_s).to eq("3.97")
    end
  end
end
