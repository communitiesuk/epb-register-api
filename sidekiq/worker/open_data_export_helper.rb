module Worker
  class OpenDataExportHelper
    def self.call_rake(rake_name: "open_data:export_assessments", assessment_types: nil)
      ENV["INSTANCE_NAME"] = "mhclg-epb-s3-open-data-export"
      monthly_rake = rake_task(rake_name)
      last_month = get_last_months_dates
      rake_name == "open_data:export_assessments" ? monthly_rake.invoke(ENV["OPEN_DATA_REPORT_TYPE"], assessment_types, last_month[:start_date], last_month[:end_date]) : monthly_rake.invoke("for_odc")
      monthly_rake.reenable
    end

    def self.get_last_months_dates
      end_date = Date.today.strftime("%Y-%m-01")
      start_date = Date.yesterday.strftime("%Y-%m-01")
      { start_date:, end_date: }
    end

    def self.rake_task(name)
      rake = Rake::Application.new
      Rake.application = rake
      rake.load_rakefile
      rake.tasks.find { |task| task.to_s == name }
    end
  end
end
