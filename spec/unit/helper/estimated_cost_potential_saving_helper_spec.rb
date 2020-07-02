# frozen_string_literal: true

describe Helper::EstimatedCostPotentialSavingHelper do
  let(:helper) { described_class.new }
  let(:lighting_cost_current) { 875.84 }
  let(:heating_cost_current) { 875.27 }
  let(:hot_water_cost_current) { 875.95 }
  let(:lighting_cost_potential) { 575.02 }
  let(:heating_cost_potential) { 234.75 }
  let(:hot_water_cost_potential) { 293.79 }

  context "when given the lighting, heating and hot water costs current and potential" do
    it "returns the estimated energy cost" do
      result =
        helper.estimated_cost(
          lighting_cost_current,
          heating_cost_current,
          hot_water_cost_current,
        )
      expect(result).to eq("2627.06")
    end

    it "returns the potential saving" do
      result =
        helper.potential_saving(
          lighting_cost_potential,
          heating_cost_potential,
          hot_water_cost_potential,
          2625,
        )
      expect(result).to eq("1521.44")
    end
  end
end
