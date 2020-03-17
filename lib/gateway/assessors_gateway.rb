module Gateway
  class AssessorsGateway
    class TooManyResults < Exception; end

    class Assessor < ActiveRecord::Base
      def to_domain
        scheme = Scheme.find_by(scheme_id: self[:registered_by])
        Domain::Assessor.new(
          self[:scheme_assessor_id],
          self[:first_name],
          self[:last_name],
          self[:middle_names],
          self[:date_of_birth],
          self[:email],
          self[:telephone_number],
          scheme[:scheme_id],
          scheme[:name],
          self[:search_results_comparison_postcode],
          self[:domestic_rd_sap_qualification],
          self[:non_domestic_sp3_qualification]
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

    def search(latitude, longitude, entries = 10)
      qualification = 'domestic_rd_sap_qualification'

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
          Domain::Assessor.new(
            row['scheme_assessor_id'],
            row['first_name'],
            row['last_name'],
            row['middle_names'],
            row['date_of_birth'],
            row['email'],
            row['telephone_number'],
            row['registered_by'],
            row['scheme_name'],
            row['search_results_comparison_postcode'],
            row['domestic_rd_sap_qualification'],
            row['non_domestic_sp3_qualification']
          )

        distance_result = row['distance']
        full_hash = { assessor: assessor.to_hash, distance: distance_result }

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
        assessor =
          Domain::Assessor.new(
            row['scheme_assessor_id'],
            row['first_name'],
            row['last_name'],
            row['middle_names'],
            row['date_of_birth'],
            row['email'],
            row['telephone_number'],
            row['registered_by'],
            row['scheme_name'],
            row['search_results_comparison_postcode'],
            row['domestic_rd_sap_qualification'],
            row['non_domestic_sp3_qualification']
          )

        result.push(assessor.to_hash)
      end
      result
    end
  end
end
