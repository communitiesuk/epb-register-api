desc 'Import some random assessors data'

task :truncate_assessor do
  if ENV['STAGE'] == 'production'
    exit
  end

  ActiveRecord::Base.connection.execute('TRUNCATE TABLE assessors RESTART IDENTITY CASCADE')
end

task :generate_assessor do
  if ENV['STAGE'] == 'production'
    exit
  end

  result = ActiveRecord::Base.connection.execute('SELECT * FROM postcode_geolocation ORDER BY random() LIMIT 1000')

  ActiveRecord::Base.logger = nil

  first_names = %w(Abul Jaseera Lawrence Kevin Christine Tito Matt Barry Yusuf Andreas Becks Dean Marten Tristan)
  last_names = %w(Kibria Abubacker Goldstien Keenoy Horrocks Sarrionandia Anderson Anderson Sheikh England Henze Wanless Wetterberg Tonks)

  result.each_with_index do |row, index|
    first_name = first_names[rand(first_names.size)]
    last_name = last_names[rand(last_names.size)]
    query =
      "INSERT INTO
        assessors
          (
            first_name, last_name, date_of_birth, registered_by,
            scheme_assessor_id, telephone_number, email,
            search_results_comparison_postcode,
            domestic_rd_sap_qualification
          )
        VALUES(
          '#{first_name}',
          '#{last_name}',
          '#{rand(1970..1999)}-01-01',
          #{rand(1..6)},
          '#{index}',
          '0#{rand(1000000..9999999)}',
          '#{first_name.downcase + '.' + last_name.downcase}@epb-assessors.com',
          '#{row['postcode']}',
          'ACTIVE'
        )"

    ActiveRecord::Base.connection.execute(query)
  end
end
