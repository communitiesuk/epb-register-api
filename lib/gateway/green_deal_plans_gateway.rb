module Gateway
  class GreenDealPlansGateway
    class GreenDealPlan < ActiveRecord::Base; end

    def exists?(green_deal_plan_id)
      sql = <<-SQL
        SELECT EXISTS (
          SELECT *
          FROM green_deal_assessments
          WHERE green_deal_plan_id = $1
        )
      SQL

      results =
        ActiveRecord::Base.connection.exec_query(
          sql,
          "SQL",
          [
            ActiveRecord::Relation::QueryAttribute.new(
              "green_deal_plan_id",
              green_deal_plan_id,
              ActiveRecord::Type::String.new,
            ),
          ],
        )

      results.map { |result| result["exists"] }.reduce
    end

    def add(green_deal_plan, assessment_id)
      GreenDealPlan.create green_deal_plan.to_record

      sql = <<-SQL
        INSERT INTO green_deal_assessments (green_deal_plan_id, assessment_id)
        VALUES ($1, $2)
      SQL

      ActiveRecord::Base.connection.exec_query(
        sql,
        "SQL",
        [
          ActiveRecord::Relation::QueryAttribute.new(
            "green_deal_plan_id",
            green_deal_plan.green_deal_plan_id,
            ActiveRecord::Type::String.new,
          ),
          ActiveRecord::Relation::QueryAttribute.new(
            "assessment_id",
            assessment_id,
            ActiveRecord::Type::String.new,
          ),
        ],
      )
    end

    def update(green_deal_plan, plan_id)
      plan = GreenDealPlan.find_by green_deal_plan_id: plan_id

      plan.update green_deal_plan.to_record
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

    def delete(plan_id)
      sql =
        "DELETE FROM green_deal_plans WHERE green_deal_plan_id = '#{
          ActiveRecord::Base.sanitize_sql(plan_id)
        }'"

      GreenDealPlan.connection.execute(sql)
    end
  end
end
