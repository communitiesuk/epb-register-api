describe Gateway::AssessmentStatisticsGateway, set_with_timecop: true do
  subject(:gateway) { described_class.new }

  let(:scheme_assessor_id) do
    "TEST123456"
  end
  let(:scheme_id) do
    "9999"
  end

  let(:add_assessor) do
    Gateway::SchemesGateway::Scheme.create(scheme_id:)
    Gateway::AssessorsGateway::Assessor.create(scheme_assessor_id:, first_name: "test_forename", last_name: "test_surname", date_of_birth: "1970-01-05", registered_by: scheme_id)
  end
  let(:today) do
    Time.now.strftime("%Y-%m-%d")
  end

  describe "#save" do
    let(:saved_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM assessment_statistics ORDER BY assessment_type")
    end

    it "save the expected data to the database" do
      gateway.save(assessment_type: "RdSAP", assessments_count: 56, rating_average: 29, day_date: Time.now.to_date, transaction_type: 2, country: "England")
      gateway.save(assessment_type: "SAP", assessments_count: 79, rating_average: 28, day_date: Time.now.to_date, transaction_type: 1, country: "Northern Ireland")

      expect(saved_data.first.symbolize_keys).to match a_hash_including({ assessment_type: "RdSAP", assessments_count: 56, rating_average: 29.0, day_date: Time.now.to_date, transaction_type: 2, country: "England" })
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
      gateway.save(assessment_type: "RdSAP", assessments_count: 79, rating_average: 28, day_date: Date.parse("01-09-2021"), transaction_type: 1)
      gateway.save(assessment_type: "RdSAP", assessments_count: 79, rating_average: 28, day_date: Date.parse("02-08-2021"), transaction_type: 1)
      expect(gateway.min_assessment_date.strftime("%F")).to eq("2021-08-02")
    end
  end

  describe "#fetch_monthly_stats" do
    before do
      england = "England"
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
        { "num_assessments" => 24, "rating_average" => 28.0, "month" => "2021-08", "assessment_type" => "RdSAP" },
        { "num_assessments" => 81, "rating_average" => 60.98, "month" => "2021-09", "assessment_type" => "RdSAP" },
        { "num_assessments" => 138, "rating_average" => 58.12, "month" => "2021-09", "assessment_type" => "SAP" },

      ]
    end

    it "returns the expected aggregate data for last month" do
      results = gateway.fetch_monthly_stats.sort_by { |h| [h["month"], h["assessment_type"]] }
      expect(results).to eq expected_results
    end

    it "does not return the additional row - data saved in the current month" do
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
        { "assessment_type" => "SAP", "number_of_assessments" => 92, "rating_average" => 75.65 },
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
    context "when saving data using the country_id to determine the country" do
      before do
        add_assessor
        Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0000", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: "2010-01-04", date_registered: "2010-01-05", created_at: "2010-01-05", date_of_expiry:  "2070-01-05", current_energy_efficiency_rating: 50)

        Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0007", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: "2010-01-04", date_registered: "2010-01-05", created_at: "2010-01-05", date_of_expiry:  "2070-01-05", current_energy_efficiency_rating: 20)

        Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0002", scheme_assessor_id:, type_of_assessment: "RdSAP", date_of_assessment: "2010-01-04", date_registered: "2010-01-05", created_at: "2010-01-05", date_of_expiry: "2070-01-05", current_energy_efficiency_rating: 20)

        Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0001", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: "2010-01-01", date_registered: "2010-01-01", created_at: "2010-01-02", date_of_expiry: "2070-01-05", current_energy_efficiency_rating: 50)

        Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0005", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: today, date_registered: today, created_at: today, date_of_expiry: "2070-01-05", current_energy_efficiency_rating: 50, postcode: "BT1 1AA")

        add_countries
        add_assessment_country_ids
      end

      it "calls the method without error" do
        expect { gateway.save_daily_stats(date: date_today) }.not_to raise_error
      end

      it "calls the method without error when no data to be saved" do
        expect { gateway.save_daily_stats(date: "2020-01-28") }.not_to raise_error
      end

      it "does not import migrated data" do
        count = Gateway::AssessmentStatisticsGateway::AssessmentStatistics.count
        Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-1005", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: date_today, date_registered: date_today, created_at: date_today, date_of_expiry: "2070-01-05", migrated: true)
        gateway.save_daily_stats(date: date_today)
        count_after = Gateway::AssessmentStatisticsGateway::AssessmentStatistics.count
        expect(count_after).not_to be < count
      end

      it "saves the only the assessments lodged today for NI" do
        gateway.save_daily_stats(date: date_today)
        results = Gateway::AssessmentStatisticsGateway::AssessmentStatistics.all
        expect(results.length).to eq(1)
        expect(results[0]["country"]).to eq("Northern Ireland")
      end

      it "saves the 2 SAP assessments lodged on the 2010-01-05" do
        gateway.save_daily_stats(date: "2010-01-05")
        sap_results = Gateway::AssessmentStatisticsGateway::AssessmentStatistics.find_by(assessment_type: "SAP")
        expect(sap_results.assessments_count).to eq(2)
        expect(sap_results.rating_average).to eq(35.0)
      end

      it "saves the 1 RdSAP assessments lodged on the 2010-01-05" do
        gateway.save_daily_stats(date: "2010-01-05")
        rdsap_results = Gateway::AssessmentStatisticsGateway::AssessmentStatistics.find_by(assessment_type: "RdSAP")
        expect(rdsap_results.assessments_count).to eq(1)
        expect(rdsap_results.rating_average).to eq(20)
      end

      it "saves the assessments for specific types (NOT RdSAP)" do
        types = %w[SAP CEPC DEC AC-CERT DEC-RR]
        gateway.save_daily_stats(date: "2010-01-05", assessment_types: types)
        expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where(assessment_type: "RdSAP").count).to eq 0
        expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where(assessment_type: "SAP").count).to eq 1
      end

      it "saves the assessments correct number for the different countries", :aggregate_failures do
        Gateway::AssessmentsGateway::Assessment.create(assessment_id: "9000-0000-0000-0000-0002", scheme_assessor_id:, type_of_assessment: "RdSAP", date_of_assessment: "2010-01-04", date_registered: "2010-01-05", created_at: "2010-01-05", date_of_expiry: "2070-01-05", current_energy_efficiency_rating: 20, postcode: "BT1 1AA")
        Gateway::AssessmentsCountryIdGateway::AssessmentsCountryId.create(assessment_id: "9000-0000-0000-0000-0002", country_id: 4)
        gateway.save_daily_stats(date: "2010-01-05")
        expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where(country: "England").count).to eq 2
        expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where(country: "Northern Ireland").count).to eq 1
      end

      it "raises an error if invalid assessment types are passed" do
        types =  %w[TEST CEPC DEC AC-CERT DEC-RR]
        expect { gateway.save_daily_stats(date: "2010-01-05", assessment_types: types) }.to raise_error(StandardError, "Invalid types")
      end
    end
  end

  describe "reload_data" do
    before do
      Timecop.freeze(2024, 1, 1, 0, 0, 0)
      add_assessor
      add_countries
      today = Time.now.strftime("%Y-%m-%d")
      yesterday = Time.new(2023,12,31,0,0,0).strftime("%Y-%m-%d")

      # expect these to be deleted
      Gateway::AssessmentStatisticsGateway::AssessmentStatistics.create(assessments_count: 93, assessment_type: "RdSAP", rating_average: 42.0, day_date: "2020-01-01", country: "England & Wales")
      Gateway::AssessmentStatisticsGateway::AssessmentStatistics.create(assessments_count: 8, assessment_type: "SAP", rating_average: 42.0, day_date: "2020-01-01", country: "Northern & Ireland")

      # this is out of date range
      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0000", scheme_assessor_id:, type_of_assessment: "RdSAP", date_of_assessment: "2010-01-04", date_registered: "2010-01-05", created_at: "2010-01-05", date_of_expiry:  "2070-01-05", current_energy_efficiency_rating: 50)

      # this is a valid RdSAP in range in England
      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0002", scheme_assessor_id:, type_of_assessment: "RdSAP", date_of_assessment: "2020-10-02", date_registered: "2020-10-02", created_at: "2020-10-02", date_of_expiry:  "2070-01-05", current_energy_efficiency_rating: 50)

      # this is a valid RdSAP in range in England
      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0003", scheme_assessor_id:, type_of_assessment: "RdSAP", date_of_assessment: yesterday, date_registered: yesterday, created_at: yesterday, date_of_expiry: "2070-01-05", current_energy_efficiency_rating: 75)

      # this is a valid SAP in range in Northern Ireland
      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0004", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: yesterday, date_registered: yesterday, created_at: yesterday, date_of_expiry:  "2070-01-05", current_energy_efficiency_rating: 75, postcode: "BT1 1AA")

      # this is a valid SAP in range in England
      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0005", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: yesterday, date_registered: yesterday, created_at: yesterday, date_of_expiry:  "2070-01-05", current_energy_efficiency_rating: 75)

      # this is a valid SAP in range to be updated to Scotland 'Other'
      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0006", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: yesterday, date_registered: yesterday, created_at: yesterday, date_of_expiry:  "2070-01-05", current_energy_efficiency_rating: 75)

      # this is a valid SAP in range to be updated to Unknown 'Other'
      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0007", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: yesterday, date_registered: yesterday, created_at: yesterday, date_of_expiry:  "2070-01-05", current_energy_efficiency_rating: 75)

      # this is a valid SAP in range to be updated to England and Wales 'England'
      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0008", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: yesterday, date_registered: yesterday, created_at: yesterday, date_of_expiry:  "2070-01-05", current_energy_efficiency_rating: 75)

      # this is lodged today so should not be included
      Gateway::AssessmentsGateway::Assessment.create(assessment_id: "0000-0000-0000-0000-0009", scheme_assessor_id:, type_of_assessment: "SAP", date_of_assessment: today, date_registered: today, created_at: today, date_of_expiry:  "2070-01-05", current_energy_efficiency_rating: 82)

      add_assessment_country_ids

      Gateway::AssessmentsCountryIdGateway::AssessmentsCountryId.update("0000-0000-0000-0000-0007", country_id: 3)
      Gateway::AssessmentsCountryIdGateway::AssessmentsCountryId.update("0000-0000-0000-0000-0006", country_id: 5)
      Gateway::AssessmentsCountryIdGateway::AssessmentsCountryId.update("0000-0000-0000-0000-0008", country_id: 2)
      gateway.reload_data
    end

    after do
      Timecop.return
    end

    context "when deleting existing data from the stats table and reloading"

    it "saves the data in the correct grouping", :aggregate_failure do
      expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.count).to eq 5
      expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where(assessment_type: "RdSAP").count).to eq 2
      expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where(assessment_type: "SAP").count).to eq 3
    end

    it "does not insert the epc lodged before 2020-10-01" do
      expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where("day_date <  '2020-10-01'").count).to eq 0
    end

    it "does not insert the epc lodged today" do
      expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where("day_date =  '#{today}'").count).to eq 0
    end

    it "no longer contains a row for England & Wales" do
      expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where(country: "England & Wales").count).to eq 0
    end

    it "aggregate Scotland and unknown into Other" do
      expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where(country: "Other").count).to eq 1
      expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where(country: "Other").pluck(:assessments_count)).to eq [2]
    end

    it "aggregate England and Wales into England and also counts England" do
      expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where(country: "England").count).to eq 3
      expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where(country: "England", assessment_type: "RdSAP").pluck(:assessments_count)).to eq [1, 1]
      expect(Gateway::AssessmentStatisticsGateway::AssessmentStatistics.where(country: "England", assessment_type: "SAP").pluck(:assessments_count)).to eq [2]
    end
  end
end
