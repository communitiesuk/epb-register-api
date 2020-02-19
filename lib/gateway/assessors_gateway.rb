module Gateway
  class AssessorsGateway
    class TooManyResults < Exception; end

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
          assessor[:search_results_comparison_postcode],
        qualifications: {
          domestic_energy_performance_certificates:
            if assessor[:domestic_energy_performance_qualification] == 'ACTIVE'
              'ACTIVE'
            else
              'INACTIVE'
            end
        }
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

    def search(latitude, longitude, entries = 10)
      qualification = 'domestic_energy_performance_qualification'

      response =
        Assessor.connection.execute(
          "SELECT
          first_name, last_name, middle_names, date_of_birth, registered_by,
          scheme_assessor_id, telephone_number, email,
          search_results_comparison_postcode, domestic_energy_performance_qualification,
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
        assessor_hash = to_hash(row.symbolize_keys)
        distance_result = row['distance']

        full_hash = { assessor: assessor_hash, distance: distance_result }

        result.push(full_hash)
      end
      result
    end

    def search_by(name, max_length = 20)
      response =
        Assessor.connection.execute(
          "SELECT
          first_name, last_name, middle_names, date_of_birth, registered_by,
          scheme_assessor_id, telephone_number, email,
          search_results_comparison_postcode, domestic_energy_performance_qualification

        FROM assessors
        WHERE
          CONCAT(first_name, ' ', last_name) LIKE '#{
            ActiveRecord::Base.sanitize_sql(name)
          }'
        LIMIT #{ max_length+1 }
        "
        )

      raise TooManyResults if response.count > max_length

      puts "error not here..."

      result = []
      response.each do |row|
        result.push(to_hash(row.symbolize_keys))
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
      assessor[:domestic_energy_performance_qualification] =
        if (
             assessor[:qualifications] &&
               assessor[:qualifications][
                 :domestic_energy_performance_certificates
               ]
           )
          assessor[:qualifications][:domestic_energy_performance_certificates]
        else
          nil
        end
      assessor.delete(:contact_details)
      assessor.delete(:qualifications)
      assessor
    end
  end
end
