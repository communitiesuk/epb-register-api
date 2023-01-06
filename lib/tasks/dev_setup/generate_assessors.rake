namespace :dev_data do
  desc "Truncate assessors data"
  task :truncate_assessors do
    Tasks::TaskHelpers.quit_if_production

    ActiveRecord::Base.connection.exec_query("TRUNCATE TABLE assessors RESTART IDENTITY CASCADE")
  end

  desc "Import some random assessors data"
  task :generate_assessors do
    Tasks::TaskHelpers.quit_if_production

    schemes = ActiveRecord::Base.connection.exec_query("SELECT * FROM schemes")
    schemes.each do |scheme|
      ActiveRecord::Base.logger = nil

      first_names = %w[Abul Jaseera Lawrence Kevin Christine Tito Matt Barry Yusuf Andreas Becks Dean Marten Tristan Rebecca George]
      last_names = %w[Kibria Abubacker Goldstien Keenoy Horrocks Sarrionandia Anderson Anderson Sheikh England Henze Wanless Wetterberg Tonks Pye Schena]
      also_known_as = %w[Bob Cat Lynn Polly Rob Gill Mary Dave]
      address_line1 = ["1 Grove Buildings", "17a", "The Cottage", "Manor Hall", "9c Skipton Buildings"]
      address_line2 = ["Red Street", "Blue Walk", "Green Way", "Brown Road", "Silver Lane"]
      address_line3 = ["District 9", "The Hights", "Duck Grange", "Lower Fields", "Upper Marshes"]
      town = %w[Newcastle London Whapping Liverpool Manchester Dublin]
      postcode = ["NE13 3RE", "CR90 6NM", "S44 4ME", "BR1 7OK", "BT1 4WS", "PL7 3ED"]
      company_reg_no = %w[7892922 8245271 ND2536 KY63453 9872056]
      company_website = ["webbymcwebsite.org", "fawcette.com", "testington.co.uk", "mock.org", "practice.it"]
      company_email = ["testemail@email.com", "emailtest@email.com", "practiceemail@email.com", "emailpractice@email.com"]
      company_name = ["My Company", "Your Company", "Big Organisation", "Much Profit LTD", "The Business", "An Organisation"]

      5.times do |index|
        first_name = first_names.sample
        last_name = last_names.sample
        internal_also_known_as = also_known_as.sample
        internal_address_line1 = address_line1.sample
        internal_address_line2 = address_line2.sample
        internal_address_line3 = address_line3.sample
        internal_town = town.sample
        internal_postcode = postcode.sample
        internal_company_reg_no = company_reg_no.sample
        internal_company_address_line1 = address_line1.sample
        internal_company_address_line2 = address_line2.sample
        internal_company_address_line3 = address_line3.sample
        internal_company_town = town.sample
        internal_company_postcode = postcode.sample
        internal_company_website = company_website.sample
        internal_company_telephone_number = "0#{rand(1_000_000..9_999_999)}"
        internal_company_email = company_email.sample
        internal_company_name = company_name.sample
        scheme_assessor_id = (scheme["name"][0..3] + index.to_s.rjust(6, "0")).upcase
        date_of_birth = "#{rand(1970..1999)}-01-01"
        telephone_number = "0#{rand(1_000_000..9_999_999)}"
        email = "#{"#{first_name.downcase}.#{last_name.downcase}"}@epb-assessors.com"

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
                domestic_sap_qualification,
                gda_qualification
              )
            VALUES(
              '#{first_name}',
              '#{last_name}',
              '#{date_of_birth}',
              #{scheme['scheme_id']},
              '#{scheme_assessor_id}',
              '#{telephone_number}',
              '#{email}',
              '#{internal_postcode}',
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
              'ACTIVE',
              'ACTIVE',
              'ACTIVE',
              'ACTIVE',
              'ACTIVE',
              'ACTIVE',
              'ACTIVE',
              'ACTIVE',
              'ACTIVE'
            )
            ON CONFLICT (scheme_assessor_id) DO UPDATE SET
                first_name	=	'#{first_name}',
                last_name	= '#{last_name}',
                date_of_birth	=	'#{date_of_birth}',
                registered_by	=	'#{scheme['scheme_id']}',
                scheme_assessor_id	=	'#{scheme_assessor_id}',
                telephone_number	=	'#{telephone_number}',
                email	=	'#{email}',
                search_results_comparison_postcode	=	'#{postcode}',
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
                domestic_rd_sap_qualification	=	'ACTIVE',
                non_domestic_sp3_qualification = 'ACTIVE',
                non_domestic_cc4_qualification = 'ACTIVE',
                non_domestic_dec_qualification = 'ACTIVE',
                non_domestic_nos3_qualification	=	'ACTIVE',
                non_domestic_nos5_qualification	=	'ACTIVE',
                non_domestic_nos4_qualification	=	'ACTIVE',
                domestic_sap_qualification	=	'ACTIVE',
                gda_qualification = 'ACTIVE'
            "
        ActiveRecord::Base.connection.exec_query(query)
      end
    end
  end
end
