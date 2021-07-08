task :qa_rake do
  pp 'this is the worker rake'
  results = ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) as cnt FROM assessors", "SQL")
  pp results.first["cnt"]

end
