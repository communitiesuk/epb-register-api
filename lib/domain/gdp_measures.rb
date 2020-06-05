module Domain
  class GDPMeasures
    attr_reader :sequence

    def initialize(
      green_deal_plan_id: nil,
      sequence: nil,
      measure_type: nil,
      product: nil,
      repaid_date: nil
    )
      @green_deal_plan_id = green_deal_plan_id, @sequence = sequence
      @measure_type = measure_type
      @product = product, @repaid_date = Date.strptime(repaid_date, "%Y-%m-%d")
    end

    def to_hash
      {
        green_deal_plan_id: @green_deal_plan_id,
        sequence: @sequence,
        measure_type: @measure_type,
        product: @product,
        repaid_date: @repaid_date.strftime("%Y-%m-%d"),
      }
    end

    def to_record
      {
        green_deal_plan_id: @green_deal_plan_id,
        sequence: @sequence,
        measure_type: @measure_type,
        product: @product,
        repaid_date: @repaid_date,
      }
    end
  end
end
