module Helper
  class GreenDealSavingsCalculator
    def self.calculate(data)
      output =
        data.map do |row|
          # (GDP_FUEL_SAVINGS.STANDING_CHARGE_FRACTION * GDP_FUEL_PRICE_DATA.STANDING_CHARGE) + (0.01 * GDP_FUEL_PRICE_DATA.FUEL_PRICE * GDP_FUEL_SAVINGS.FUEL_SAVING);
          row.each { |k, v| row[k] = BigDecimal(v, 2) }

          (row[:standing_charge_fraction] * row[:standing_charge]) +
            (BigDecimal(0.01, 2) * row[:fuel_price] * row[:fuel_saving])
        end

      output.sum.round
    end
  end
end
