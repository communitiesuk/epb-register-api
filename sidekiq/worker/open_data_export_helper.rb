module Worker
  module OpenDataExportHelper
    def self.call_rake(rake_name: "open_data:export_assessments", assessment_types: nil)
      monthly_rake = rake_task(rake_name)
      last_month = get_last_months_dates
      whether_for_odc = output_to_test_dir? ? "not_for_odc" : "for_odc"
      rake_name == "open_data:export_assessments" ? monthly_rake.invoke(whether_for_odc, assessment_types, last_month[:start_date], last_month[:end_date]) : monthly_rake.invoke(whether_for_odc)
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

    def self.output_to_test_dir?
      Helper::Toggles.enabled? "register-api-write-ode-to-test-directory"
    end

    private_class_method :rake_task, :output_to_test_dir?
  end
end
