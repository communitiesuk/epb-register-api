
desc "Exporting assessments data for Open Data"

task :open_data_export do

  if ENV["ASSESSMENT_TYPE"] == "CEPC"
     # export_open_data_commercial = UseCase::ExportOpenDataCommercial.new
     # export_open_data_commercial.execute
      "this is inside the if clause"
  end

   "this is outside the if clause"

end
