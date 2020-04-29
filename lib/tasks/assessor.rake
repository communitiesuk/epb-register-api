desc 'Truncate assessors data'

task :truncate_assessor do
  if ENV['STAGE'] == 'production'
    exit
  end

  ActiveRecord::Base.connection.execute('TRUNCATE TABLE assessors RESTART IDENTITY CASCADE')
end

desc 'Import some random assessors data'

task :generate_assessor do
  if ENV['STAGE'] == 'production'
    exit
  end

  schemes = ActiveRecord::Base.connection.execute('SELECT * FROM schemes')

  schemes.each do |scheme|
    result = ActiveRecord::Base.connection.execute('SELECT * FROM postcode_geolocation ORDER BY random() LIMIT 166')

    ActiveRecord::Base.logger = nil

    first_names = %w[Abul Jaseera Lawrence Kevin Christine Tito Matt Barry Yusuf Andreas Becks Dean Marten Tristan Rebecca George]
    last_names = %w[Kibria Abubacker Goldstien Keenoy Horrocks Sarrionandia Anderson Anderson Sheikh England Henze Wanless Wetterberg Tonks Pye Schena]

    result.each_with_index do |row, index|
      first_name = first_names[rand(first_names.size)]
      last_name = last_names[rand(last_names.size)]

      rd_sap = rand(2)
      sp3 = rand(2)
      nos5 = rand(2)
      cc4 = rand(2)
      dec = rand(2)
      nos3 = rand(2)
      nos4 = rand(2)
      sap = rand(2)

      scheme_assessor_id = (scheme['name'][0..5] + index.to_s.rjust(5, '0')).upcase

      query =
        "INSERT INTO
          assessors
            (
              first_name,
              last_name,
              date_of_birth,
              registered_by,
              scheme_assessor_id,
              telephone_number,
              email,
              search_results_comparison_postcode,
              domestic_rd_sap_qualification,
              non_domestic_sp3_qualification,
              non_domestic_cc4_qualification,
              non_domestic_dec_qualification,
              non_domestic_nos3_qualification,
              non_domestic_nos5_qualification,
              non_domestic_nos4_qualification,
              domestic_sap_qualification
            )
          VALUES(
            '#{first_name}',
            '#{last_name}',
            '#{rand(1970..1999)}-01-01',
            #{scheme['scheme_id']},
            '#{scheme_assessor_id}',
            '0#{rand(1000000..9999999)}',
            '#{first_name.downcase + '.' + last_name.downcase}@epb-assessors.com',
            '#{row['postcode']}',
            '#{rd_sap != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{sp3 != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{cc4 != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{dec != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{nos3 != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{nos5 != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{nos4 != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{sap != 0 ? 'ACTIVE' : 'INACTIVE'}'
          )"

      ActiveRecord::Base.connection.execute(query)
    end
  end
end
