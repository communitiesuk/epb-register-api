module Gateway
  class AssessorsGateway
    SCHEME_ASSESSOR_ID_COLUMN = :scheme_assessor_id
    FIRST_NAME_COLUMN = :first_name
    LAST_NAME_COLUMN = :last_name
    MIDDLE_NAMES_COLUMN = :middle_names
    DATE_OF_BIRTH_COLUMN = :date_of_birth
    EMAIL_COLUMN = :email
    TELEPHONE_NUMBER_COLUMN = :telephone_number
    SEARCH_RESULTS_COMPARISON_POSTCODE_COLUMN = :search_results_comparison_postcode
    ALSO_KNOWN_AS = :also_known_as
    ADDRESS_LINE1 = :address_line1
    ADDRESS_LINE2 = :address_line2
    ADDRESS_LINE3 = :address_line3
    TOWN = :town
    POSTCODE = :postcode
    COMPANY_REG_NO = :company_reg_no
    COMPANY_ADDRESS_LINE1 = :company_address_line1
    COMPANY_ADDRESS_LINE2 = :company_address_line2
    COMPANY_ADDRESS_LINE3 = :company_address_line3
    COMPANY_TOWN = :company_town
    COMPANY_POSTCODE = :company_postcode
    COMPANY_WEBSITE = :company_website
    COMPANY_TELEPHONE_NUMBER = :company_telephone_number
    COMPANY_EMAIL = :company_email
    COMPANY_NAME = :company_name
    DOMESTIC_SAP_COLUMN = :domestic_sap_qualification
    DOMESTIC_RD_SAP_COLUMN = :domestic_rd_sap_qualification
    NON_DOMESTIC_SP3_COLUMN = :non_domestic_sp3_qualification
    NON_DOMESTIC_CC4_COLUMN = :non_domestic_cc4_qualification
    NON_DOMESTIC_DEC_COLUMN = :non_domestic_dec_qualification
    NON_DOMESTIC_NOS3_COLUMN = :non_domestic_nos3_qualification
    NON_DOMESTIC_NOS4_COLUMN = :non_domestic_nos4_qualification
    NON_DOMESTIC_NOS5_COLUMN = :non_domestic_nos5_qualification
    GDA_COLUMN = :gda_qualification
    REGISTERED_BY_COLUMN = :registered_by

    def row_to_assessor_domain(row)
      scheme_name = row["scheme_name"]
      unless scheme_name
        scheme = Scheme.find_by(scheme_id: row[REGISTERED_BY_COLUMN.to_s])
        scheme_name = scheme[:name]
      end
      Domain::Assessor.new(
        scheme_assessor_id: row[SCHEME_ASSESSOR_ID_COLUMN.to_s],
        first_name: row[FIRST_NAME_COLUMN.to_s],
        last_name: row[LAST_NAME_COLUMN.to_s],
        middle_names: row[MIDDLE_NAMES_COLUMN.to_s],
        date_of_birth: row[DATE_OF_BIRTH_COLUMN.to_s],
        email: row[EMAIL_COLUMN.to_s],
        telephone_number: row[TELEPHONE_NUMBER_COLUMN.to_s],
        registered_by_id: row[REGISTERED_BY_COLUMN.to_s],
        registered_by_name: scheme_name,
        search_results_comparison_postcode:
          row[SEARCH_RESULTS_COMPARISON_POSTCODE_COLUMN.to_s],
        also_known_as: row[ALSO_KNOWN_AS.to_s],
        address_line1: row[ADDRESS_LINE1.to_s],
        address_line2: row[ADDRESS_LINE2.to_s],
        address_line3: row[ADDRESS_LINE3.to_s],
        town: row[TOWN.to_s],
        postcode: row[POSTCODE.to_s],
        company_reg_no: row[COMPANY_REG_NO.to_s],
        company_address_line1: row[COMPANY_ADDRESS_LINE1.to_s],
        company_address_line2: row[COMPANY_ADDRESS_LINE2.to_s],
        company_address_line3: row[COMPANY_ADDRESS_LINE3.to_s],
        company_town: row[COMPANY_TOWN.to_s],
        company_postcode: row[COMPANY_POSTCODE.to_s],
        company_website: row[COMPANY_WEBSITE.to_s],
        company_telephone_number: row[COMPANY_TELEPHONE_NUMBER.to_s],
        company_email: row[COMPANY_EMAIL.to_s],
        company_name: row[COMPANY_NAME.to_s],
        domestic_sap_qualification: row[DOMESTIC_SAP_COLUMN.to_s],
        domestic_rd_sap_qualification: row[DOMESTIC_RD_SAP_COLUMN.to_s],
        non_domestic_sp3_qualification: row[NON_DOMESTIC_SP3_COLUMN.to_s],
        non_domestic_cc4_qualification: row[NON_DOMESTIC_CC4_COLUMN.to_s],
        non_domestic_dec_qualification: row[NON_DOMESTIC_DEC_COLUMN.to_s],
        non_domestic_nos3_qualification: row[NON_DOMESTIC_NOS3_COLUMN.to_s],
        non_domestic_nos4_qualification: row[NON_DOMESTIC_NOS4_COLUMN.to_s],
        non_domestic_nos5_qualification: row[NON_DOMESTIC_NOS5_COLUMN.to_s],
        gda_qualification: row[GDA_COLUMN.to_s],
      )
    end

    class Assessor < ActiveRecord::Base; end
    class Scheme < ActiveRecord::Base; end

    def qualification_to_column(qualification)
      case qualification
      when "domesticSap"
        DOMESTIC_SAP_COLUMN
      when "domesticRdSap"
        DOMESTIC_RD_SAP_COLUMN
      when "nonDomesticSp3"
        NON_DOMESTIC_SP3_COLUMN
      when "nonDomesticCc4"
        NON_DOMESTIC_CC4_COLUMN
      when "nonDomesticDec"
        NON_DOMESTIC_DEC_COLUMN
      when "nonDomesticNos3"
        NON_DOMESTIC_NOS3_COLUMN
      when "nonDomesticNos4"
        NON_DOMESTIC_NOS4_COLUMN
      when "nonDomesticNos5"
        NON_DOMESTIC_NOS5_COLUMN
      when "gda"
        GDA_COLUMN
      else
        raise ArgumentError, "Unrecognised qualification type"
      end
    end

    def qualification_columns_to_sql(columns)
      selectors =
        columns.map do |c|
          "#{Assessor.connection.quote_column_name(c)} = 'ACTIVE'"
        end
      selectors.join(" OR ")
    end

    def fetch(scheme_assessor_id)
      assessor = Assessor.find_by(scheme_assessor_id: scheme_assessor_id)
      assessor ? row_to_assessor_domain(assessor) : nil
    end

    def fetch_list(scheme_id)
      assessors = Assessor.where(registered_by: scheme_id)
      assessors.map { |assessor| row_to_assessor_domain(assessor) }
    end

    def update(assessor)
      existing_assessor =
        Assessor.find_by(scheme_assessor_id: assessor.scheme_assessor_id)
      if existing_assessor
        existing_assessor.update(assessor.to_record)
      else
        Assessor.create(assessor.to_record)
      end
    end

    def search(latitude, longitude, qualifications, entries = 10)
      qualification_selector =
        qualification_columns_to_sql(
          qualifications.map { |q| qualification_to_column(q) },
        )

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "latitude",
          latitude,
          ActiveRecord::Type::Float.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "longitude",
          longitude,
          ActiveRecord::Type::Float.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "entries",
          entries,
          ActiveRecord::Type::Integer.new,
        ),
      ]

      response =
        Assessor.connection.exec_query(
          "SELECT
          first_name, last_name, middle_names, date_of_birth, registered_by,
           scheme_assessor_id, telephone_number, email, c.name AS scheme_name,
           search_results_comparison_postcode, domestic_sap_qualification,
           domestic_rd_sap_qualification, non_domestic_sp3_qualification,
           non_domestic_cc4_qualification, non_domestic_dec_qualification,
           non_domestic_nos3_qualification, non_domestic_nos4_qualification,
           non_domestic_nos5_qualification, gda_qualification,
            (
              sqrt(abs(POWER(69.1 * (a.latitude - $1 ), 2) +
              POWER(69.1 * (a.longitude - $2) * cos( $1 / 57.3), 2)))
            ) AS distance
          FROM postcode_geolocation a
          INNER JOIN assessors b ON(b.search_results_comparison_postcode = a.postcode)
          LEFT JOIN schemes c ON(b.registered_by = c.scheme_id)
          WHERE
            #{
            qualification_selector
          }
            AND a.latitude BETWEEN ($1 - 1) AND ($1 + 1)
            AND a.longitude BETWEEN ($2 - 1) AND ($2 + 1)
          ORDER BY distance LIMIT $3",
          "SQL",
          binds,
        )

      result = []
      response.each do |row|
        assessor_hash = row_to_assessor_domain(row).to_hash
        assessor_hash[:distance_from_postcode_in_miles] = row["distance"]

        result.push(assessor_hash)
      end
      result
    end

    def search_by(
      name: "", max_response_size: 20, loose_match: false, exclude: []
    )
      sql =
        'SELECT
          first_name, last_name, middle_names, date_of_birth, registered_by,
          scheme_assessor_id, telephone_number, email, b.name AS scheme_name,
          search_results_comparison_postcode, also_known_as, address_line1,
          address_line2, address_line3, town, postcode, company_reg_no,
          company_address_line1, company_address_line2, company_address_line3,
          company_town, company_postcode, company_website, company_telephone_number,
          company_email, company_name, domestic_sap_qualification,
          domestic_rd_sap_qualification, non_domestic_sp3_qualification,
          non_domestic_cc4_qualification, non_domestic_dec_qualification,
          non_domestic_nos3_qualification, non_domestic_nos4_qualification,
          non_domestic_nos5_qualification, gda_qualification

        FROM assessors a
        LEFT JOIN schemes b ON(a.registered_by = b.scheme_id)
        WHERE
          1=1
      '

      unless exclude.empty?
        sql << "AND scheme_assessor_id NOT IN('" + exclude.join("', '") + "')"
      end

      if loose_match
        names = name.split(" ")

        sql <<
          " AND((first_name ILIKE '#{
            ActiveRecord::Base.sanitize_sql(names[0])
          }%' AND last_name ILIKE '#{
            ActiveRecord::Base.sanitize_sql(names[1])
          }%')"
        sql <<
          " OR (first_name ILIKE '#{
            ActiveRecord::Base.sanitize_sql(names[1])
          }%' AND last_name ILIKE '#{
            ActiveRecord::Base.sanitize_sql(names[0])
          }%'))"
      else
        sql <<
          " AND CONCAT(first_name, ' ', last_name) ILIKE '#{
            ActiveRecord::Base.sanitize_sql(name)
          }'"
        if max_response_size.positive?
          sql << "LIMIT " + (max_response_size + 1).to_s
        end
      end

      response = Assessor.connection.execute(sql)

      result = []
      response.each { |row| result.push(row_to_assessor_domain(row).to_hash) }
      result
    end
  end
end
