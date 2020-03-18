module Gateway
  class AssessorsGateway
    SCHEME_ASSESSOR_ID_COLUMN = :scheme_assessor_id
    FIRST_NAME_COLUMN = :first_name
    LAST_NAME_COLUMN = :last_name
    MIDDLE_NAMES_COLUMN = :middle_names
    DATE_OF_BIRTH_COLUMN = :date_of_birth
    EMAIL_COLUMN = :email
    TELEPHONE_NUMBER_COLUMN = :telephone_number
    SEARCH_RESULTS_COMPARISON_POSTCODE_COLUMN =
      :search_results_comparison_postcode
    DOMESTIC_RD_SAP_COLUMN = :domestic_rd_sap_qualification
    NON_DOMESTIC_SP3_COLUMN = :non_domestic_sp3_qualification

    def row_to_assessor_domain(row)
          Domain::Assessor.new(
              row[SCHEME_ASSESSOR_ID_COLUMN.to_s],
              row[FIRST_NAME_COLUMN.to_s],
              row[LAST_NAME_COLUMN.to_s],
              row[MIDDLE_NAMES_COLUMN.to_s],
              row[DATE_OF_BIRTH_COLUMN.to_s],
              row[EMAIL_COLUMN.to_s],
              row[TELEPHONE_NUMBER_COLUMN.to_s],
              row['registered_by'],
              row['scheme_name'],
              row[SEARCH_RESULTS_COMPARISON_POSTCODE_COLUMN.to_s],
              row[DOMESTIC_RD_SAP_COLUMN.to_s],
              row[NON_DOMESTIC_SP3_COLUMN.to_s]
          )
    end

    class Assessor < ActiveRecord::Base
      def to_domain
        scheme = Scheme.find_by(scheme_id: self[:registered_by])
        Domain::Assessor.new(
          self[SCHEME_ASSESSOR_ID_COLUMN],
          self[FIRST_NAME_COLUMN],
          self[LAST_NAME_COLUMN],
          self[MIDDLE_NAMES_COLUMN],
          self[DATE_OF_BIRTH_COLUMN],
          self[EMAIL_COLUMN],
          self[TELEPHONE_NUMBER_COLUMN],
          scheme[:scheme_id],
          scheme[:name],
          self[SEARCH_RESULTS_COMPARISON_POSTCODE_COLUMN],
          self[DOMESTIC_RD_SAP_COLUMN],
          self[NON_DOMESTIC_SP3_COLUMN]
        )
      end
    end

    class Scheme < ActiveRecord::Base; end

    def fetch(scheme_assessor_id)
      assessor = Assessor.find_by(scheme_assessor_id: scheme_assessor_id)
      assessor ? assessor.to_domain : nil
    end

    def fetch_list(scheme_id)
      assessor = Assessor.where(registered_by: scheme_id)
      assessor.map(&:to_domain)
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

    def search(latitude, longitude, qualification_type, entries = 10)
      if qualification_type == 'domesticRdSap'
        qualification = DOMESTIC_RD_SAP_COLUMN
      elsif qualification_type == 'nonDomesticSp3'
        qualification = NON_DOMESTIC_SP3_COLUMN
      end

      response =
        Assessor.connection.execute(
          "SELECT
          first_name, last_name, middle_names, date_of_birth, registered_by,
          scheme_assessor_id, telephone_number, email, c.name AS scheme_name,
          search_results_comparison_postcode, domestic_rd_sap_qualification,
          (
            sqrt(abs(POWER(69.1 * (a.latitude - #{
            latitude.to_f
          } ), 2) +
            POWER(69.1 * (a.longitude - #{
            longitude.to_f
          } ) * cos( #{
            latitude.to_f
          } / 57.3), 2)))
          ) AS distance

        FROM postcode_geolocation a
        INNER JOIN assessors b ON(b.search_results_comparison_postcode = a.postcode)
        LEFT JOIN schemes c ON(b.registered_by = c.scheme_id)
        WHERE
          #{
            qualification
          } = 'ACTIVE'
          AND a.latitude BETWEEN #{
            (latitude - 1).to_f
          } AND #{(latitude + 1).to_f}
          AND a.longitude BETWEEN #{
            (longitude - 1).to_f
          } AND #{(longitude + 1).to_f}

        ORDER BY distance LIMIT #{
            entries
          }"
        )

      result = []
      response.each do |row|
        assessor =
        distance_result = row['distance']
        full_hash = { assessor: row_to_assessor_domain(row).to_hash, distance: distance_result }

        result.push(full_hash)
      end
      result
    end

    def search_by(
      name: '', max_response_size: 20, loose_match: false, exclude: []
    )
      sql =
        'SELECT
          first_name, last_name, middle_names, date_of_birth, registered_by,
          scheme_assessor_id, telephone_number, email, b.name AS scheme_name,
          search_results_comparison_postcode, domestic_rd_sap_qualification,
          non_domestic_sp3_qualification

        FROM assessors a
        LEFT JOIN schemes b ON(a.registered_by = b.scheme_id)
        WHERE
          1=1
      '

      unless exclude.empty?
        sql << "AND scheme_assessor_id NOT IN('" + exclude.join("', '") + "')"
      end

      if loose_match
        names = name.split(' ')

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
        sql << 'LIMIT ' + (max_response_size + 1).to_s if max_response_size > 0
      end

      response = Assessor.connection.execute(sql)

      result = []
      response.each do |row|
        result.push(row_to_assessor_domain(row).to_hash)
      end
      result
    end
  end
end
