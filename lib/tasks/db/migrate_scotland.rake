namespace :db do

  # Rake::Task["db:migrate"].enhance(["db:migrate_scotland"])

  desc "Run db migrations on the scotland schema"
  task :migrate_scotland  do
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true

    ActiveRecord::Base.connection.schema_search_path = "scotland"

    context = ActiveRecord::MigrationContext.new(["db/migrate_scotland"])
    context.migrate

    ActiveRecord::Base.connection.schema_search_path = "public"
  end

  desc "Rollback migrations on the scotland db"
  task :rollback_scotland do
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true

    ActiveRecord::Base.connection.schema_search_path = "scotland"

    context = ActiveRecord::MigrationContext.new(["db/migrate_scotland"])
    context.rollback

    ActiveRecord::Base.connection.schema_search_path = "public"
  end
end



