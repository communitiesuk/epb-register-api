desc "Truncate assessors data"

task :truncate_assessor do
  if ENV["STAGE"] == "production"
    exit
  end

  ActiveRecord::Base.connection.execute("TRUNCATE TABLE assessors RESTART IDENTITY CASCADE")
end

desc "Import some random assessors data"

task :generate_assessor do
  if ENV["STAGE"] == "production"
    exit
  end

  schemes = ActiveRecord::Base.connection.execute("SELECT * FROM schemes")

  schemes.each do |scheme|
    result = ActiveRecord::Base.connection.execute("SELECT * FROM postcode_geolocation ORDER BY random() LIMIT 166")

    ActiveRecord::Base.logger = nil

    first_names = %w[Abul Jaseera Lawrence Kevin Christine Tito Matt Barry Yusuf Andreas Becks Dean Marten Tristan Rebecca George]
    last_names = %w[Kibria Abubacker Goldstien Keenoy Horrocks Sarrionandia Anderson Anderson Sheikh England Henze Wanless Wetterberg Tonks Pye Schena]
    also_known_as = %w[Bob Cat Lynn Polly Rob Gill Mary Dave]
    address_line1 = ["1 Grove Buildings", "17a", "The Cottage", "Manor Hall", "9c Skipton Buildings"]
    address_line2 = ["Red Street", "Blue Walk", "Green Way", "Brown Road", "Silver Lane"]
    address_line3 = ["District 9", "The Hights", "Duck Grange", "Lower Fields", "Upper Marshes"]
    town = %w[Newcastle London Whapping Liverpool Manchester Dublin]
    postcode = ["NE14 3RE", "C23 6NM", "SH92 4ME", "BR1 7OK"]
    company_reg_no = %w[7892922 8245271 ND2536 KY63453 9872056]
    company_address_line1 = ["1 Grove Buildings", "17a", "The Cottage", "Manor Hall", "9c Skipton Buildings"]
    company_address_line2 = ["Red Street", "Blue Walk", "Green Way", "Brown Road", "Silver Lane"]
    company_address_line3 = ["District 9", "The Hights", "Duck Grange", "Lower Fields", "Upper Marshes"]
    company_town = %w[Newcastle London Whapping Liverpool Manchester Dublin]
    company_postcode = ["NE14 3RE", "C23 6NM", "SH92 4ME", "BR1 7OK"]
    company_website = ["webbymcwebsite.org", "fawcette.com", "testington.co.uk", "mock.org", "practice.it"]
    company_telephone_number = %w[019192983 93746537398 0922665 826472665 09813784]
    company_email = ["testemail@email.com", "emailtest@email.com", "practiceemail@email.com", "emailpractice@email.com"]
    company_name = ["My Company", "Your Company", "Big Organisation", "Much Profit LTD", "The Business", "An Organisation"]

    result.each_with_index do |row, index|
      first_name = first_names[rand(first_names.size)]
      last_name = last_names[rand(last_names.size)]
      internal_also_known_as = also_known_as.sample
      internal_address_line1 = address_line1.sample
      internal_address_line2 = address_line2.sample
      internal_address_line3 = address_line3.sample
      internal_town = town.sample
      internal_postcode = postcode.sample
      internal_company_reg_no = company_reg_no.sample
      internal_company_address_line1 = company_address_line1.sample
      internal_company_address_line2 = company_address_line2.sample
      internal_company_address_line3 = company_address_line3.sample
      internal_company_town = company_town.sample
      internal_company_postcode = company_postcode.sample
      internal_company_website = company_website.sample
      internal_company_telephone_number = company_telephone_number.sample
      internal_company_email = company_email.sample
      internal_company_name = company_name.sample

      rd_sap = rand(2)
      sp3 = rand(2)
      nos5 = rand(2)
      cc4 = rand(2)
      dec = rand(2)
      nos3 = rand(2)
      nos4 = rand(2)
      sap = rand(2)

      scheme_assessor_id = (scheme["name"][0..3] + index.to_s.rjust(6, "0")).upcase

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
              also_known_as,
              address_line1,
              address_line2,
              address_line3,
              town,
              postcode,
              company_reg_no,
              company_address_line1,
              company_address_line2,
              company_address_line3,
              company_town,
              company_postcode,
              company_website,
              company_telephone_number,
              company_email,
              company_name,
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
            '#{internal_also_known_as}',
            '#{internal_address_line1}',
            '#{internal_address_line2}',
            '#{internal_address_line3}',
            '#{internal_town}',
            '#{internal_postcode}',
            '#{internal_company_reg_no}',
            '#{internal_company_address_line1}',
            '#{internal_company_address_line2}',
            '#{internal_company_address_line3}',
            '#{internal_company_town}',
            '#{internal_company_postcode}',
            '#{internal_company_website}',
            '#{internal_company_telephone_number}',
            '#{internal_company_email}',
            '#{internal_company_name}',
            '#{rd_sap != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{sp3 != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{cc4 != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{dec != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{nos3 != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{nos5 != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{nos4 != 0 ? 'ACTIVE' : 'INACTIVE'}',
            '#{sap != 0 ? 'ACTIVE' : 'INACTIVE'}'
          )
          ON CONFLICT (scheme_assessor_id) DO UPDATE SET
              first_name	=	'#{first_name}',
              last_name	= '#{last_name}',
              date_of_birth	=	'#{rand(1970..1999)}-01-01',
              registered_by	=	#{scheme['scheme_id']},
              scheme_assessor_id	=	'#{scheme_assessor_id}',
              telephone_number	=	'0#{rand(1000000..9999999)}',
              email	=	'#{first_name.downcase + '.' + last_name.downcase}@epb-assessors.com',
              search_results_comparison_postcode	=	'#{row['postcode']}',
              also_known_as	=	'#{internal_also_known_as}',
              address_line1	=	'#{internal_address_line1}',
              address_line2	=	'#{internal_address_line2}',
              address_line3	=	'#{internal_address_line3}',
              town	=	'#{internal_town}',
              postcode	=	'#{internal_postcode}',
              company_reg_no	=	'#{internal_company_reg_no}',
              company_address_line1	=	'#{internal_company_address_line1}',
              company_address_line2	=	'#{internal_company_address_line2}',
              company_address_line3	=	'#{internal_company_address_line3}',
              company_town	=	'#{internal_company_town}',
              company_postcode = '#{internal_company_postcode}',
              company_website	=	'#{internal_company_website}',
              company_telephone_number	=	'#{internal_company_telephone_number}',
              company_email	=	'#{internal_company_email}',
              company_name = '#{internal_company_name}',
              domestic_rd_sap_qualification	=	'#{rd_sap != 0 ? 'ACTIVE' : 'INACTIVE'}',
              non_domestic_sp3_qualification = '#{sp3 != 0 ? 'ACTIVE' : 'INACTIVE'}',
              non_domestic_cc4_qualification = '#{cc4 != 0 ? 'ACTIVE' : 'INACTIVE'}',
              non_domestic_dec_qualification = '#{dec != 0 ? 'ACTIVE' : 'INACTIVE'}',
              non_domestic_nos3_qualification	=	'#{nos3 != 0 ? 'ACTIVE' : 'INACTIVE'}',
              non_domestic_nos5_qualification	=	'#{nos5 != 0 ? 'ACTIVE' : 'INACTIVE'}',
              non_domestic_nos4_qualification	=	'#{nos4 != 0 ? 'ACTIVE' : 'INACTIVE'}',
              domestic_sap_qualification	=	'#{sap != 0 ? 'ACTIVE' : 'INACTIVE'}'
          "

      ActiveRecord::Base.connection.execute(query)
    end
  end
end
