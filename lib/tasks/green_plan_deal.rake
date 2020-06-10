task :import_gdp_plans do
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE green_deal_plans RESTART IDENTITY CASCADE")
  ActiveRecord::Base.logger = nil

  raw_plans = File.read File.join Dir.pwd, "lib/json/HCR_GREEN_DEAL_PLANS.json"
  plans = JSON.parse(raw_plans)

  charges = {}
  plans["CHARGES"].map do |charges_row|
    charges[charges_row["PLAN_ID"]] = [] unless charges[charges_row["PLAN_ID"]]
    charges[charges_row["PLAN_ID"]].push({
      start_date: charges_row["START_DATE"],
      end_date: charges_row["END_DATE"],
      daily_charge: charges_row["DAILY_CHARGE"],
    })
  end

  plans["GREEN_DEAL_PLANS"].each do |row|
    query = "INSERT INTO
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
                measures
              )
              VALUES
              (
                '#{ActiveRecord::Base.sanitize_sql(row['PLAN_ID'])}',
                '#{ActiveRecord::Base.sanitize_sql(row['START_DATE'])}',
                '#{ActiveRecord::Base.sanitize_sql(row['END_DATE'])}',
                '#{ActiveRecord::Base.sanitize_sql(row['CONTACT_NAME'])}',
                '#{ActiveRecord::Base.sanitize_sql(row['CONTACT_TELEPHONE'])}',
                '#{ActiveRecord::Base.sanitize_sql(row['CONTACT_EMAIL'].gsub("'", "\\'"))}',
                '#{ActiveRecord::Base.sanitize_sql(row['INTEREST_RATE'])}',
                '#{ActiveRecord::Base.sanitize_sql(row['FIXED_INTEREST_RATE_IND'])}',
                '#{ActiveRecord::Base.sanitize_sql(row['INTEREST_UPLIFT'])}',
                #{row['INTEREST_UPLIFT_DATE'] ? "'" + ActiveRecord::Base.sanitize_sql(row['INTEREST_UPLIFT_DATE']) + "'" : 'NULL'},
                '#{ActiveRecord::Base.sanitize_sql(row['CCA_IND'])}',
                '#{ActiveRecord::Base.sanitize_sql(row['STRUCTURE_CHANGED_IND'])}',
                '#{ActiveRecord::Base.sanitize_sql(row['MEASURES_REMOVED_IND'])}',
                '#{ActiveRecord::Base.sanitize_sql(charges[row['PLAN_ID']].to_json)}'
              )"

    ActiveRecord::Base.connection.execute(query)
  end
end
