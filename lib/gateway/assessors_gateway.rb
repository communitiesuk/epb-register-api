module Gateway
  class AssessorsGateway
    class Assessor < ActiveRecord::Base
      def to_hash
        Gateway::AssessorsGateway.new.to_hash(self)
      end
    end

    def to_hash(assessor)
      {
        first_name: assessor[:first_name],
        last_name: assessor[:last_name],
        middle_names: assessor[:middle_names],
        registered_by: assessor[:registered_by],
        scheme_assessor_id: assessor[:scheme_assessor_id],
        date_of_birth:
          if assessor[:date_of_birth].methods.include?(:strftime)
            assessor[:date_of_birth].strftime('%Y-%m-%d')
          else
            Date.parse(assessor[:date_of_birth])
          end,
        contact_details: {
          telephone_number: assessor[:telephone_number], email: assessor[:email]
        },
        search_results_comparison_postcode:
          assessor[:search_results_comparison_postcode]
      }
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

    def search(latitude, longitude, entries = 100)
      response =
        Assessor.connection.execute(
          "SELECT
          first_name, last_name, middle_names, date_of_birth, registered_by,
          scheme_assessor_id, telephone_number, email,
          search_results_comparison_postcode,
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
        WHERE
          a.latitude BETWEEN #{
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
        hash = to_hash(row.symbolize_keys)

        hash[:distance] = row['distance']

        result.push(hash)
      end

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
