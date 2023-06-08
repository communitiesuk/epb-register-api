namespace :codebuild do
  desc "Enable trigram extension on build and test"
  task :enable_trigram_extension do
    ActiveRecord::Base.connection.exec_query("CREATE EXTENSION IF NOT EXISTS pg_trgm")
  end
end
