module Gateway
  class AssessorsGateway
    class Assessor < ActiveRecord::Base
      def to_hash
        {
          first_name: self[:first_name],
          last_name: self[:last_name],
          middle_names: self[:middle_names],
          registered_by: self[:registered_by],
          scheme_assessor_id: self[:scheme_assessor_id],
          date_of_birth: self[:date_of_birth].strftime('%Y-%m-%d'),
          contact_details: {
            telephone_number: self[:telephone_number], email: self[:email]
          },
          search_results_comparison_postcode:
            self[:search_results_comparison_postcode]
        }
      end
    end

    def fetch(scheme_assessor_id)
      assessor = Assessor.find_by(scheme_assessor_id: scheme_assessor_id)
      assessor ? assessor.to_hash : nil
    end

    def update(scheme_assessor_id, registered_by, assessor_details)
      assessor = assessor_details.dup
      assessor[:registered_by] = registered_by
      assessor[:scheme_assessor_id] = scheme_assessor_id

      existing_assessor =
        Assessor.find_by(
          scheme_assessor_id: scheme_assessor_id, registered_by: registered_by
        )

      assessor = flatten(assessor)

      if existing_assessor
        existing_assessor.update(assessor)
      else
        Assessor.create(assessor)
      end
    end

    def search(latitude, longitude)
      db = Assessor.connection.raw_connection

      salt = rand.to_s

      db.prepare(
        'assessors_by_geolocation' + salt,
        'SELECT
          first_name, last_name, middle_names, date_of_birth, registered_by,
          scheme_assessor_id, telephone_number, email,
          search_results_comparison_postcode,
          (
            sqrt(abs(POWER(69.1 * (a.latitude - $1 ), 2) +
            POWER(69.1 * (a.longitude - $2 ) * cos( $1 / 57.3), 2)))
          ) AS distance

        FROM postcode_geolocation a
        INNER JOIN assessors b ON(b.search_results_comparison_postcode = a.postcode)
        WHERE
          a.latitude BETWEEN $3 AND $4
          AND a.longitude BETWEEN $5 AND $6

        ORDER BY distance LIMIT 100'
      )

      response =
        db.exec_prepared(
          'assessors_by_geolocation' + salt,
          [
            latitude,
            longitude,
            (latitude - 1),
            (latitude + 1),
            (longitude - 1),
            (longitude + 1)
          ]
        )

      result = []
      response.each { |row| result << row }

      result
    end

    private

    def flatten(assessor)
      assessor[:telephone_number] =
        if assessor.key?(:contact_details)
          assessor[:contact_details][:telephone_number]
        else
          ''
        end
      assessor[:email] =
        if assessor.key?(:contact_details)
          assessor[:contact_details][:email]
        else
          ''
        end
      assessor.delete(:contact_details)
      assessor
    end
  end
end
