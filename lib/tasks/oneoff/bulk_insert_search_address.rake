namespace :oneoff do
  desc "Bulk insert missing assessment addresses into the search address table to improve searching"

  task :bulk_insert_search_address do
    ApiFactory.bulk_insert_search_address_use_case.execute
  end
end
