module Gateway
  class GreenDealPlansGateway
    class GreenDealPlan < ActiveRecord::Base; end

    def add(green_deal_plan)
      GreenDealPlan.create(green_deal_plan.to_record)
    end

    def fetch(assessment_id)
      sql =
        "SELECT b.green_deal_plan_id, b.start_date, b.end_date,
                b.provider_name, b.provider_telephone, b.provider_email,
                b.interest_rate, b.fixed_interest_rate, b.charge_uplift_amount,
                b.charge_uplift_date, b.cca_regulated, b.structure_changed, b.measures_removed,
                b.charges, b.measures, b.savings
           FROM green_deal_assessments a LEFT JOIN green_deal_plans b
           ON (a.green_deal_plan_id = b.green_deal_plan_id)
           WHERE assessment_id = '#{
          ActiveRecord::Base.sanitize_sql(assessment_id)
        }'"

      response = GreenDealPlan.connection.execute(sql)
      result = []

      response.each do |row|
        row.symbolize_keys!
        row[:charges] = JSON.parse(row[:charges], symbolize_names: true)
        row[:measures] = JSON.parse(row[:measures], symbolize_names: true)
        row[:savings] = JSON.parse(row[:savings], symbolize_names: true)

        green_deal_hash = Domain::GreenDealPlan.new(row)

        return green_deal_hash
      end

      result
    end
  end
end
