describe Gateway::AssessmentStatisticsGateway do
  subject(:gateway) { described_class.new }

  describe "#save" do
    let(:saved_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_statistics ORDER BY assessment_type")
    end

    it "save the expected data to the database" do
      gateway.save(assessment_type: "RdSAP", assessments_count: 56, rating_average: 29, day_date: Time.now.to_date, transaction_type: 2, country: "England & Wales")
      gateway.save(assessment_type: "SAP", assessments_count: 79, rating_average: 28, day_date: Time.now.to_date, transaction_type: 1, country: "Northern Ireland")

      expect(saved_data.first.symbolize_keys).to match a_hash_including({ assessment_type: "RdSAP", assessments_count: 56, rating_average: 29.0, day_date: Time.now.to_date, transaction_type: 2, country: "England & Wales" })
      expect(saved_data.last.symbolize_keys).to match a_hash_including({ assessment_type: "SAP", assessments_count: 79, rating_average: 28.0, day_date: Time.now.to_date, transaction_type: 1, country: "Northern Ireland" })
    end

    it "can save nil values for rating_average and transaction_type" do
      expect { gateway.save(assessment_type: "AC-Report", assessments_count: 20, rating_average: nil, day_date: Time.now.to_date, transaction_type: nil) }.not_to raise_error
    end

    it "raises and key constraint error if the same data is saved more then once" do
      gateway.save(assessment_type: "RdSAP", assessments_count: 56, rating_average: 29, day_date: Time.now.to_date, transaction_type: 2)
      expect { gateway.save(assessment_type: "RdSAP", assessments_count: 79, rating_average: 28, day_date: Time.now.to_date, transaction_type: 2) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#min_assessment_date" do
    it "returns the date yesterday if there is no stat date present" do
      expect(gateway.min_assessment_date).to eq(Time.now.to_date - 1)
    end

    it "returns the earliest data we have stats data for" do
      gateway.save(assessment_type: "RdSAP", assessments_count: 56, rating_average: 29, day_date: Time.now.to_date, transaction_type: 2)
      gateway.save(assessment_type: "RdSAP", assessments_count: 79, rating_average: 28, day_date: Date.parse("01-09-2021"), transaction_type: 1)
      gateway.save(assessment_type: "RdSAP", assessments_count: 79, rating_average: 28, day_date: Date.parse("02-08-2021"), transaction_type: 1)
      expect(gateway.min_assessment_date.strftime("%F")).to eq("2021-08-02")
    end
  end

  describe "#fetch_monthly_stats" do
    before do
      england = "England & Wales"
      gateway.save(assessment_type: "SAP", assessments_count: 82, rating_average: 78, day_date:  Date.parse("04-07-2021"), transaction_type: 1, country: england)
      gateway.save(assessment_type: "SAP", assessments_count: 82, rating_average: 78, day_date:  Date.parse("04-09-2021"), transaction_type: 2, country: england)
      gateway.save(assessment_type: "SAP", assessments_count: 56, rating_average: 29, day_date:  Date.parse("03-09-2021"), transaction_type: 2, country: england)
      gateway.save(assessment_type: "RdSAP", assessments_count: 2, rating_average: 60, day_date:  Date.parse("30-09-2021"), transaction_type: 1, country: england)
      gateway.save(assessment_type: "RdSAP", assessments_count: 79, rating_average: 61, day_date: Date.parse("01-09-2021"), transaction_type: 1, country: england)
      gateway.save(assessment_type: "RdSAP", assessments_count: 24, rating_average: 28, day_date: Date.parse("02-08-2021"), transaction_type: 4, country: england)
    end

    let(:expected_results) do
      [
        { "num_assessments" => 82, "rating_average" => 78.0, "month" => "2021-07", "assessment_type" => "SAP" },
        { "num_assessments" => 24, "rating_average" => 28.0, "month" => "2021-08", "assessment_type" => "RdSAP"  },
        { "num_assessments" => 81, "rating_average" => 60.5, "month" => "2021-09", "assessment_type" => "RdSAP"  },
        { "num_assessments" => 138, "rating_average" => 53.5, "month" => "2021-09", "assessment_type" => "SAP" },

      ]
    end

    it "returns the expected aggregate data for last month" do
      results = gateway.fetch_monthly_stats.sort_by { |h| [h["month"], h["assessment_type"]] }
      expect(results).to eq expected_results
    end

    it "does not return the additional row - data saved in the current month" do
      gateway.save(assessment_type: "RdSAP", assessments_count: 24, rating_average: 28, day_date: Time.now, transaction_type: 4)
      expect(gateway.fetch_monthly_stats.length).to eq(4)
    end
  end

  describe "#fetch_daily_stats_by_date" do
    before do
      gateway.save(assessment_type: "SAP", assessments_count: 82, rating_average: 80, day_date:  Date.parse("04-07-2021"), transaction_type: 1, country: "England & Wales")
      gateway.save(assessment_type: "SAP", assessments_count: 10, rating_average: 40, day_date:  Date.parse("04-07-2021"), transaction_type: 1, country: "Northern Ireland")
      gateway.save(assessment_type: "RdSAP", assessments_count: 24, rating_average: 28, day_date: Date.parse("04-07-2021"), transaction_type: 4, country: "England & Wales")
      gateway.save(assessment_type: "DEC", assessments_count: 5, rating_average: 0, day_date: Date.parse("04-07-2021"), transaction_type: nil, country: "England & Wales")
      gateway.save(assessment_type: "AC-CERT", assessments_count: 14, rating_average: 0, day_date: Date.parse("04-07-2021"), transaction_type: nil, country: "England & Wales")
    end

    let(:expected_results) do
      [
        { "assessment_type" => "SAP", "number_of_assessments" => 92, "rating_average" => 60.0 },
        { "assessment_type" => "RdSAP", "number_of_assessments" => 24, "rating_average" => 28.0 },
        { "assessment_type" => "DEC", "number_of_assessments" => 5, "rating_average" => 0.0 },
        { "assessment_type" => "AC-CERT", "number_of_assessments" => 14, "rating_average" => 0.0 },
      ]
    end

    it "returns the expected aggregate data for a given date" do
      results = gateway.fetch_daily_stats_by_date("2021-07-04")

      expect(results).to eq(expected_results)
    end
  end

  describe "#fetch_monthly_stats_by_country" do
    before do
      gateway.save(assessment_type: "SAP", assessments_count: 82, rating_average: 78, day_date: Date.parse("04-07-2021"), transaction_type: 1, country: "England & Wales")
      gateway.save(assessment_type: "RdSAP", assessments_count: 93, rating_average: 62, day_date: Date.parse("04-09-2021"), transaction_type: 2, country: "England & Wales")
      gateway.save(assessment_type: "SAP", assessments_count: 10, rating_average: 42, day_date: Date.parse("04-09-2021"), transaction_type: 2, country: "Northern Ireland")
      gateway.save(assessment_type: "RdSAP", assessments_count: 5, rating_average: 50, day_date: Date.parse("04-09-2021"), transaction_type: 2, country: "Northern Ireland")
    end

    let(:expected_results) do
      [{ "num_assessments" => 82, "rating_average" => 78.0, "month" => "2021-07", "assessment_type" => "SAP", "country" => "England & Wales" },
       { "num_assessments" => 93, "rating_average" => 62.0, "month" => "2021-09", "assessment_type" => "RdSAP",  "country" => "England & Wales" },
       { "num_assessments" => 5, "rating_average" => 50.0, "month" => "2021-09", "assessment_type" => "RdSAP",   "country" => "Northern Ireland" },
       { "num_assessments" => 10, "rating_average" => 42.0, "month" => "2021-09", "assessment_type" => "SAP", "country" => "Northern Ireland" }]
    end

    it "returns the expected aggregate data by country" do
      results = gateway.fetch_monthly_stats_by_country.sort_by { |h| [h["country"], h["month"], h["assessment_type"]] }
      expect(results).to eq(expected_results)
    end
  end

  describe "#save_daily_stats" do
    before do
      today = Time.now.strftime("%Y-%m-%d")
      ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id) VALUES ('9999')")
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessors (scheme_assessor_id, first_name, last_name, date_of_birth, registered_by)
        VALUES ('TEST123456', 'test_forename', 'test_surname', '1970-01-05', 9999)",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, current_energy_efficiency_rating)
        VALUES ('0000-0000-0000-0000-0000', 'TEST123456', 'SAP', '2010-01-04', '2010-01-05', '2010-01-05', '2070-01-05', 50)",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, current_energy_efficiency_rating)
        VALUES ('0000-0000-0000-0000-0007', 'TEST123456', 'SAP', '2010-01-04', '2010-01-05', '2010-01-05', '2070-01-05', 20)",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, current_energy_efficiency_rating)
        VALUES ('0000-0000-0000-0000-0002', 'TEST123456', 'RdSAP', '2010-01-04', '2010-01-05', '2010-01-05', '2070-01-05',  20 )",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, current_energy_efficiency_rating)
        VALUES ('0000-0000-0000-0000-0001', 'TEST123456', 'SAP', '2010-01-01', '2010-01-01', '2010-01-02', '2070-01-02', 50)",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, postcode)
        VALUES ('0000-0000-0000-0000-0005', 'TEST123456', 'SAP', '#{today}', '#{today}', '#{today}', '2070-01-05', 'BT1 1AA')",
      )
    end

    it "calls the method without error" do
      expect { gateway.save_daily_stats(date: date_today) }.not_to raise_error
    end

    it "calls the method without error when no data to be saved" do
      expect { gateway.save_daily_stats(date: "2020-01-28") }.not_to raise_error
    end

    it "does not import migrated data" do
      results = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_statistics")
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, type_of_assessment, date_of_assessment, date_registered, created_at, date_of_expiry, migrated)
        VALUES ('0000-0000-0000-0000-1005', 'TEST123456', 'SAP', '#{date_today}', '#{date_today}', '#{date_today}', '2070-01-05', TRUE)",
      )
      gateway.save_daily_stats(date: date_today)
      results_after = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_statistics")
      expect(results.length).not_to eq(results_after.length)
    end

    it "saves the only the assessments lodged today for NI" do
      gateway.save_daily_stats(date: date_today)
      results = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_statistics")
      expect(results.length).to eq(1)
      expect(results[0]["country"]).to eq("Northern Ireland")
    end

    it "saves the 2 SAP assessments lodged on the 2010-01-05" do
      gateway.save_daily_stats(date: "2010-01-05")
      sap_results = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_statistics WHERE assessment_type = 'SAP'")
      expect(sap_results[0]["assessments_count"]).to eq(2)
      expect(sap_results[0]["rating_average"]).to eq(35.0)
      expect(sap_results.length).to eq(1)
    end

    it "saves the 1 RdSAP assessments lodged on the 2010-01-05" do
      gateway.save_daily_stats(date: "2010-01-05")
      rdsap_results = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_statistics WHERE assessment_type = 'RdSAP'")
      expect(rdsap_results[0]["assessments_count"]).to eq(1)
      expect(rdsap_results[0]["rating_average"]).to eq(20)
      expect(rdsap_results.length).to eq(1)
    end

    it "saves the assessments for specific types (NOT RdSAP)" do
      types = %w[SAP CEPC DEC AC-CERT DEC-RR]
      gateway.save_daily_stats(date: "2010-01-05", assessment_types: types)
      rdsap_results = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_statistics WHERE assessment_type = 'RdSAP'")
      expect(rdsap_results.length).to eq(0)
      sap_results = ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_statistics WHERE assessment_type = 'SAP'")
      expect(sap_results.length).to eq(1)
    end

    it "raises an error if invalid assessment types are passed" do
      types =  %w[TEST CEPC DEC AC-CERT DEC-RR]
      expect { gateway.save_daily_stats(date: "2010-01-05", assessment_types: types) }.to raise_error(StandardError, "Invalid types")
    end
  end
end
