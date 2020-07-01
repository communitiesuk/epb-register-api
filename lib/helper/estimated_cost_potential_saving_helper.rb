# frozen_string_literal: true

module Helper
  class EstimatedCostPotentialSavingHelper
    def estimated_cost(
      lighting_cost_current, heating_cost_current, hot_water_cost_current
    )
      [
        lighting_cost_current,
        heating_cost_current,
        hot_water_cost_current,
      ].compact.sum
    end

    def potential_saving(
      lighting_cost_potential,
      heating_cost_potential,
      hot_water_cost_potential,
      estimated_cost = BigDecimal(0)
    )
      potential_saving_sum = [
        lighting_cost_potential,
        heating_cost_potential,
        hot_water_cost_potential,
      ].compact.sum
      estimated_cost - potential_saving_sum
    end
  end
end
