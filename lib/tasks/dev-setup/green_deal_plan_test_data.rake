namespace :dev_data do

  desc "Create 25 green deal assessments as test data"
  task :seed_test_green_deal_plans do
    Tasks::TaskHelpers.quit_if_production

    ActiveRecord::Base.logger = nil

    charges = [
      [
        {
          "start_date": "2020-03-29",
          "end_date": "2030-03-29",
          "daily_charge": "0.34",
        },
        {
          "start_date": "2020-04-29",
          "end_date": "2030-12-29",
          "daily_charge": "1.34",
        },
      ].to_json,
      [
        {
          "start_date": "2022-03-29",
          "end_date": "2032-03-29",
          "daily_charge": "2.34",
        },
      ].to_json,
      [
        {
          "start_date": "2021-03-29",
          "end_date": "2032-03-29",
          "daily_charge": "0",
        },
      ].to_json,
    ]
    measures = [
      [
        {
          "product": "Hot water cylinder insulation",
          "repaid_date": "2030-03-29",
        },
      ].to_json,
      [
        {
          "product": "External wall insulation: WarmHome lagging stuff (TM)",
          "repaid_date": "2025-03-29",
        },
        {
          "product": "Hot water cylinder thermostat",
          "repaid_date": "2035-03-29",
        },
      ].to_json,
      [
        {
          "product": "Loft insulation: WarmHome lagging stuff (TM)",
          "repaid_date": "2032-03-29",
        },
      ].to_json,
    ]
    savings = [
      [
        {
          "fuel_code": "34",
          "fuel_saving": 0,
          "standing_charge_fraction": -0.3,
        },
      ].to_json,
      [
        {
          "fuel_code": "33",
          "fuel_saving": 1,
          "standing_charge_fraction": 0,
        },
      ].to_json,
      [
        {
          "fuel_code": "39",
          "fuel_saving": 10,
          "standing_charge_fraction": -0.1,
        },
        {
          "fuel_code": "41",
          "fuel_saving": 12,
          "standing_charge_fraction": -0.2,
        },
      ].to_json,
    ]

    added_plans = 0

    ActiveRecord::Base.transaction do
      assessments = ActiveRecord::Base.connection.exec_query <<-SQL
        SELECT assessment_id
        FROM assessments
        ORDER BY RANDOM()
        LIMIT 25
      SQL

      provider_names = ["My Company", "Your Company", "Big Organisation", "Much Profit LTD", "The Business", "An Organisation"]
      provider_telephones = %w[019192983 93746537398 0922665 826472665 09813784]
      provider_emails = %w[testemail@email.com emailtest@email.com practiceemail@email.com emailpractice@email.com]
      interest_rates = [14.61, 12.21, 26.30, 10.10, 15.70]
      yes_or_no = %w[Y N]
      uplift_amounts = [0, 1.24, 1.50, 0.90, 1]

      assessments.each do |row|
        green_deal_plan_id = "A#{('A'..'Z').to_a.sample}#{rand(100...2000).to_s.rjust(10, '0')}"
        start_date = "20#{rand(14..21).to_s.rjust(2, '0')}#{rand(1..12).to_s.rjust(2, '0')}#{rand(1..28).to_s.rjust(2, '0')}"
        end_date = (Date.parse(start_date) + rand(5..20).year).strftime("%Y-%m-%d")
        provider_name = provider_names.sample
        provider_telephone = provider_telephones.sample
        provider_email = provider_emails.sample
        interest_rate = interest_rates.sample
        fixed_interest_rate = yes_or_no.sample
        charge_uplift_amount = uplift_amounts.sample
        charge_uplift_date = (Date.parse(start_date) + rand(1..20).year).strftime("%Y-%m-%d")
        cca_regulated = yes_or_no.sample
        structure_changed = yes_or_no.sample
        measures_removed = yes_or_no.sample

        ActiveRecord::Base.connection.exec_query "INSERT INTO
                                                green_deal_plans
                                                (
                                                  green_deal_plan_id,
                                                  start_date,
                                                  end_date,
                                                  provider_name,
                                                  provider_telephone,
                                                  provider_email,
                                                  interest_rate,
                                                  fixed_interest_rate,
                                                  charge_uplift_amount,
                                                  charge_uplift_date,
                                                  cca_regulated,
                                                  structure_changed,
                                                  measures_removed,
                                                  charges,
                                                  measures,
                                                  savings
                                                ) VALUES (
                                                  '#{green_deal_plan_id}',
                                                  '#{start_date}',
                                                  '#{end_date}',
                                                  '#{provider_name}',
                                                  '#{provider_telephone}',
                                                  '#{provider_email}',
                                                  '#{interest_rate}',
                                                  '#{fixed_interest_rate}',
                                                  '#{charge_uplift_amount}',
                                                  '#{charge_uplift_date}',
                                                  '#{cca_regulated}',
                                                  '#{structure_changed}',
                                                  '#{measures_removed}',
                                                  '#{charges.sample}',
                                                  '#{measures.sample}',
                                                  '#{savings.sample}'
                                                )"

        ActiveRecord::Base.connection.exec_query "INSERT INTO
                                                green_deal_assessments
                                                (
                                                  green_deal_plan_id,
                                                  assessment_id
                                                )
                                                VALUES (
                                                    '#{green_deal_plan_id}',
                                                    '#{row['assessment_id']}'
                                                )"
        added_plans += 1
      end
    end

    puts "Added data for #{added_plans} test green deal plans"
  end
end
