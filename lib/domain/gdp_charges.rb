module Domain
  class GDPCharges
    attr_reader :sequence

    def initialize(
      green_deal_plan_id: nil,
      sequence: nil,
      start_date: nil,
      end_date: nil,
      daily_charge: nil
    )
      @green_deal_plan_id =
        green_deal_plan_id,
        @sequence = sequence,
        @start_date = Date.strptime(start_date, "%Y-%m-%d"),
        @end_date = Date.strptime(end_date, "%Y-%m-%d"),
        @daily_charge = daily_charge
    end

    def to_hash
      {
        green_deal_plan_id: @green_deal_plan_id,
        sequence: @sequence,
        start_date: @start_date.strftime("%Y-%m-%d"),
        end_date: @end_date.strftime("%Y-%m-%d"),
        daily_charge: @daily_charge,
      }
    end

    def to_record
      {
        green_deal_plan_id: @green_deal_plan_id,
        sequence: @sequence,
        start_date: @start_date,
        end_date: @end_date,
        daily_charge: @daily_charge,
      }
    end
  end
end
