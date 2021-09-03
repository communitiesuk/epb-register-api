namespace :data_export do
  desc "Exporting assessments data for Northern Ireland"

  task :ni_assessments do
    exporter = ApiFactory.ni_assessments_export_use_case
    exports = exporter.execute(%w[RdSAP SAP])
  end
end
