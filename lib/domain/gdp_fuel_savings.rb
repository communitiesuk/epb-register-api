module Domain
  class GDPFuelSavings
    attr_reader :sequence

    def initialize(
      green_deal_plan_id: nil,
      sequence: nil,
      fuel_code: nil,
      fuel_saving: nil,
      standing_charge_fraction: nil
    )
      @green_deal_plan_id =
        green_deal_plan_id,
        @sequence = sequence,
        @fuel_code = fuel_code,
        @fuel_saving = fuel_saving,
        @standing_charge_fraction = standing_charge_fraction
    end

    def to_hash
      {
        green_deal_plan_id: @green_deal_plan_id,
        sequence: @sequence,
        fuel_code: @fuel_code,
        fuel_saving: @fuel_saving,
        standing_charge_fraction: @standing_charge_fraction,
      }
    end

    def to_record
      {
        green_deal_plan_id: @green_deal_plan_id,
        sequence: @sequence,
        fuel_code: @fuel_code,
        fuel_saving: @fuel_saving,
        standing_charge_fraction: @standing_charge_fraction,
      }
    end
  end
end
