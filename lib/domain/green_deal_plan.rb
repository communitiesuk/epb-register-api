module Domain
  class GreenDealPlan
    attr_reader :green_deal_plan_id, :savings
    attr_writer :estimated_savings

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
      estimated_savings: nil
    )
      @green_deal_plan_id = green_deal_plan_id
      @start_date = Date.parse start_date.to_s unless start_date.nil?
      @end_date = Date.parse end_date.to_s unless end_date.nil?
      @provider_name = provider_name
      @provider_telephone = provider_telephone
      @provider_email = provider_email
      @interest_rate = interest_rate
      @fixed_interest_rate = fixed_interest_rate
      @charge_uplift_amount = charge_uplift_amount
      @charge_uplift_date =
        (Date.parse charge_uplift_date.to_s unless charge_uplift_date.nil?)
      @cca_regulated = cca_regulated
      @structure_changed = structure_changed
      @measures_removed = measures_removed
      @measures = measures
      @charges = charges
      @savings = savings
      @estimated_savings = estimated_savings
    end

    def to_hash
      {
        green_deal_plan_id: @green_deal_plan_id,
        start_date: @start_date.nil? ? nil : @start_date.strftime("%Y-%m-%d"),
        end_date: @end_date.nil? ? nil : @end_date.strftime("%Y-%m-%d"),
        provider_details: {
          name: @provider_name,
          telephone: @provider_telephone,
          email: @provider_email,
        },
        interest: {
          rate: @interest_rate,
          fixed: @fixed_interest_rate,
        },
        charge_uplift: {
          amount: @charge_uplift_amount,
          date:
            if @charge_uplift_date.nil?
              nil
            else
              @charge_uplift_date.strftime("%Y-%m-%d")
            end,
        },
        cca_regulated: @cca_regulated,
        structure_changed: @structure_changed,
        measures_removed: @measures_removed,
        measures: @measures,
        charges: @charges,
        savings: @savings,
        estimated_savings: @estimated_savings,
      }
    end

    def to_record
      {
        green_deal_plan_id: @green_deal_plan_id,
        start_date: @start_date,
        end_date: @end_date,
        provider_name: @provider_name,
        provider_telephone: @provider_telephone,
        provider_email: @provider_email,
        interest_rate: @interest_rate,
        fixed_interest_rate: @fixed_interest_rate,
        charge_uplift_amount: @charge_uplift_amount,
        charge_uplift_date: @charge_uplift_date,
        cca_regulated: @cca_regulated,
        structure_changed: @structure_changed,
        measures_removed: @measures_removed,
        measures: @measures,
        charges: @charges,
        savings: @savings,
      }
    end
  end
end
