require "openssl"

desc "Truncate green deal plans data"

task :truncate_green_deal_plans do
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE green_deal_plans RESTART IDENTITY CASCADE")
end

desc "Import green deal plans data"

task :import_green_deal_plans do
  ActiveRecord::Base.logger = nil

  uri = URI(ENV["url"])

  raw_plans = Net::HTTP.start(
    uri.host,
    uri.port,
    use_ssl: uri.scheme == "https",
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
  ) do |http|
    request = Net::HTTP::Get.new uri.request_uri
    request.basic_auth ENV["username"], ENV["password"]

    http.request request
  end

  plans = JSON.parse(raw_plans.body)

  charges = {}
  plans["CHARGES"].map do |charges_row|
    charges[charges_row["PLAN_ID"]] = [] unless charges[charges_row["PLAN_ID"]]
    charges[charges_row["PLAN_ID"]].push({
      start_date: charges_row["START_DATE"],
      end_date: charges_row["END_DATE"],
      daily_charge: charges_row["DAILY_CHARGE"],
    })
  end

  measures = {}
  plans["MEASURES"].map do |measures_row|
    measures[measures_row["PLAN_ID"]] = [] unless measures[measures_row["PLAN_ID"]]
    measures[measures_row["PLAN_ID"]].push({
      product: measures_row["PRODUCT"].gsub("'", "\\'"),
      repaid_date: measures_row["REPAID_DATE"],
    })
  end

  savings = {}
  plans["SAVINGS"].map do |savings_row|
    savings[savings_row["PLAN_ID"]] = [] unless savings[savings_row["PLAN_ID"]]
    savings[savings_row["PLAN_ID"]].push({
      fuel_code: savings_row["OA_FUEL_CODE"],
      fuel_saving: savings_row["FUEL_SAVING"],
      standing_charge_fraction: savings_row["STANDING_CHARGE_FRACTION"],
    })
  end

  assessment_ids = []
  plans["RRNS"].each do |rrn_row|
    assessment_ids[rrn_row["PLAN_KEY"]] = [] unless assessment_ids[rrn_row["PLAN_KEY"]]
    assessment_ids[rrn_row["PLAN_KEY"]].push(rrn_row["REPORT_REFERENCE_ID"])
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
                charges,
                measures,
                savings,
                assessment_id
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
                '#{ActiveRecord::Base.sanitize_sql(charges[row['PLAN_ID']].to_json)}',
                '#{ActiveRecord::Base.sanitize_sql(measures[row['PLAN_ID']].to_json)}',
                '#{ActiveRecord::Base.sanitize_sql(savings[row['PLAN_ID']].to_json)}',
                '#{ActiveRecord::Base.sanitize_sql(assessment_ids[row['PLAN_KEY']])}'
              )"

    ActiveRecord::Base.connection.execute(query)
  end
end
