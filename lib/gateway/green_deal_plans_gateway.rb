module Gateway
  class GreenDealPlansGateway
    class GreenDealPlan < ActiveRecord::Base
    end

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

      green_deal_plan.estimated_savings =
        calculate_estimated_savings plan.savings

      green_deal_plan
    end

    def fetch(assessment_id)
      sql = <<-SQL
        SELECT
          b.green_deal_plan_id, b.start_date, b.end_date,
          b.provider_name, b.provider_telephone, b.provider_email,
          b.interest_rate, b.fixed_interest_rate, b.charge_uplift_amount,
          b.charge_uplift_date, b.cca_regulated, b.structure_changed,
          b.measures_removed, b.charges, b.measures, b.savings
        FROM
          green_deal_assessments a
        INNER JOIN
          green_deal_plans b ON a.green_deal_plan_id = b.green_deal_plan_id
        WHERE
          assessment_id = #{ActiveRecord::Base.connection.quote(assessment_id)}
        ORDER BY b.green_deal_plan_id
      SQL
      response = GreenDealPlan.connection.execute(sql)
      result = []

      response.each do |row|
        row.symbolize_keys!
        row[:charges] = JSON.parse(row[:charges], symbolize_names: true)
        row[:measures] = JSON.parse(row[:measures], symbolize_names: true)
        row[:savings] = JSON.parse(row[:savings], symbolize_names: true)
        row[:estimated_savings] = calculate_estimated_savings row[:savings]

        green_deal_hash = Domain::GreenDealPlan.new(row)

        result.push(green_deal_hash)
      end

      result
    end

    def delete(plan_id)
      sql =
        "DELETE FROM green_deal_plans WHERE green_deal_plan_id = #{
          ActiveRecord::Base.connection.quote(plan_id)
        }"

      GreenDealPlan.connection.execute(sql)
    end

    def validate_fuel_codes?(fuel_codes)
      stored_codes = GreenDealPlan.connection.execute <<-SQL
        SELECT fuel_code FROM green_deal_fuel_code_map
      SQL

      stored_codes =
        stored_codes.map(&:symbolize_keys!).map { |row| row[:fuel_code] }

      valid = true

      fuel_codes.each do |code|
        valid = false unless stored_codes.include? code.to_i
      end

      valid
    end

  private

    def calculate_estimated_savings(savings)
      sql = <<-SQL
        SELECT gdfcm.fuel_code, gdfpd.fuel_heat_source, gdfpd.fuel_price, gdfpd.standing_charge
        FROM green_deal_fuel_code_map gdfcm
        INNER JOIN green_deal_fuel_price_data gdfpd
            ON gdfcm.fuel_heat_source = gdfpd.fuel_heat_source
      SQL
      fuel_pricing_data = GreenDealPlan.connection.execute(sql).entries
      fuel_pricing_data = fuel_pricing_data.map(&:symbolize_keys!)

      fuel_savings_data = []

      savings
        .map(&:symbolize_keys!)
        .each do |saving|
          pricing =
            fuel_pricing_data.detect do |datum|
              datum[:fuel_code] == saving[:fuel_code].to_i
            end

          fuel_savings_data <<
            saving.slice(:fuel_saving, :standing_charge_fraction).merge(pricing)
        end

      Helper::GreenDealSavingsCalculator.calculate fuel_savings_data
    end
  end
end
