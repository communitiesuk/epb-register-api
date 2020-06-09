module Domain
  class GreenDealPlan
    def initialize(
      green_deal_plan_id: nil,
      start_date: nil,
      end_date: nil,
      provider_name: nil,
      provider_telephone: nil,
      provider_email: nil,
      interest_rate: nil,
      fixed_interest_rate: nil,
      charge_uplift_amount: nil,
      charge_uplift_date: nil,
      cca_regulated: nil,
      structure_changed: nil,
      measures_removed: nil,
      measures: [],
      charges: [],
      savings: [],
      assessment_id: nil
    )
      @green_deal_plan_id = green_deal_plan_id
      @start_date = start_date
      @end_date = end_date
      @provider_name = provider_name
      @provider_telephone = provider_telephone
      @provider_email = provider_email
      @interest_rate = interest_rate
      @fixed_interest_rate = fixed_interest_rate
      @charge_uplift_amount = charge_uplift_amount
      @charge_uplift_date = charge_uplift_date
      @cca_regulated = cca_regulated
      @structure_changed = structure_changed
      @measures_removed = measures_removed
      @measures = measures
      @charges = charges
      @savings = savings
      @assessment_id = assessment_id
    end

    def to_hash; end
  end
end
