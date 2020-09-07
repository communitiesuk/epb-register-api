desc "Import some random schemes data"

task :generate_schemes do
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE schemes RESTART IDENTITY CASCADE")

  ActiveRecord::Base.logger = nil

  names = ["CIBSE Certification Limited", "ECMK", "Elmhurst", "Sterling", "Stroma", "Quidos"]

  names.each do |name|
    query = "INSERT INTO schemes (name) VALUES('#{name}')"

    ActiveRecord::Base.connection.execute(query)
  end
end
