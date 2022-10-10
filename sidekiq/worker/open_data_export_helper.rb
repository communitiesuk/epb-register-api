module Worker
  class OpenDataExportHelper
    def self.call_rake(assessment_types)
      monthly_rake = rake_task("open_data:export_assessments")
      monthly_rake.invoke("not_for_odc", assessment_types, get_last_months_dates[:start_date], get_last_months_dates[:end_date])
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
