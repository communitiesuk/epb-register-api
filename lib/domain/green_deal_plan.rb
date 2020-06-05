module Domain
  class GreenDealPlan
    attr_reader :green_deal_plan_id,
                :start_date,
                :end_date,
                :provider_name,
                :provider_telephone,
                :provider_email,
                :interest_rate,
                :fixed_interest_rate,
                :charge_uplift_amount,
                :charge_uplift_date,
                :cca_regulated,
                :structure_changed,
                :measures_removed
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
      measures_removed: nil
    )
      @green_deal_plan_id =
        green_deal_plan_id,
        @start_date = Date.strptime(start_date, "%Y-%m-%d"),
        @end_date = Date.strptime(end_date, "%Y-%m-%d"),
        @provider_name = provider_name,
        @provider_telephone = provider_telephone,
        @provider_email = provider_email,
        @interest_rate = interest_rate,
        @fixed_interest_rate = fixed_interest_rate,
        @charge_uplift_amount = charge_uplift_amount,
        @charge_uplift_date = Date.strptime(charge_uplift_date, "%Y-%m-%d"),
        @cca_regulated = cca_regulated,
        @structure_changed = structure_changed,
        @measures_removed = measures_removed
    end

    def to_hash
      {
        green_deal_plan_id: @green_deal_plan_id,
        start_date: @start_date.strftime("%Y-%m-%d"),
        end_date: @end_date.strftime("%Y-%m-%d"),
        provider_details: {
          provider_name: @provider_name,
          provider_telephone: @provider_telephone,
          provider_email: @provider_email,
        },
        interest: {
          interest_rate: @interest_rate,
          fixed_interest_rate: @fixed_interest_rate,
        },
        chargeUplift: {
          charge_uplift_amount: @charge_uplift_amount,
          charge_uplift_date: @charge_uplift_date.strftime("%Y-%m-%d"),
        },
        cca_regulated: @cca_regulated,
        structure_changed: @structure_changed,
        measures_removed: @measures_removed,
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
      }
    end
  end
end
