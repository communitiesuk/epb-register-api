module Gateway
  class DomesticEnergyAssessmentsGateway
    class InvalidCurrentEnergyRatingException < Exception; end
    class InvalidPotentialEnergyRatingException < Exception; end
    class DomesticEnergyAssessment < ActiveRecord::Base
      def to_hash
        Gateway::DomesticEnergyAssessmentsGateway.new.to_hash(self)
      end
    end

    def to_hash(assessment)
      {
        date_of_assessment:
          assessment[:date_of_assessment].strftime('%Y-%m-%d'),
        date_registered: assessment[:date_registered].strftime('%Y-%m-%d'),
        dwelling_type: assessment[:dwelling_type],
        type_of_assessment: assessment[:type_of_assessment],
        total_floor_area: assessment[:total_floor_area],
        assessment_id: assessment[:assessment_id],
        scheme_assessor_id: assessment[:scheme_assessor_id],
        address_summary: assessment[:address_summary],
        current_energy_efficiency_rating:
          assessment[:current_energy_efficiency_rating],
        potential_energy_efficiency_rating:
          assessment[:potential_energy_efficiency_rating],
        postcode: assessment[:postcode],
        date_of_expiry: assessment[:date_of_expiry].strftime('%Y-%m-%d'),
        address_line1: assessment[:address_line1],
        address_line2: assessment[:address_line2],
        address_line3: assessment[:address_line3],
        address_line4: assessment[:address_line4],
        town: assessment[:town],
        current_energy_efficiency_band:
          get_energy_rating_band(assessment[:current_energy_efficiency_rating]),
        potential_energy_efficiency_band:
          get_energy_rating_band(
            assessment[:potential_energy_efficiency_rating]
          )
      }
    end

    def fetch(assessment_id)
      energy_assessment =
        DomesticEnergyAssessment.find_by({ assessment_id: assessment_id })
      energy_assessment ? energy_assessment.to_hash : nil
    end

    def insert_or_update(domestic_energy_assessment)
      current_rating =
          domestic_energy_assessment.current_energy_efficiency_rating
      potential_rating =
          domestic_energy_assessment.potential_energy_efficiency_rating

      if !(current_rating.is_a?(Integer) && current_rating.between?(1, 100))
        raise InvalidCurrentEnergyRatingException
      elsif !(
      potential_rating.is_a?(Integer) && potential_rating.between?(1, 100)
      )
        raise InvalidPotentialEnergyRatingException
      else
        send_to_db(domestic_energy_assessment.assessment_id, domestic_energy_assessment.to_record)
      end
    end

    def search_by_postcode(postcode)
      sql =
        "SELECT
            scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
            type_of_assessment, total_floor_area, address_summary, current_energy_efficiency_rating,
            potential_energy_efficiency_rating, postcode, date_of_expiry,
            address_line1, address_line2, address_line3, address_line4, town
        FROM domestic_energy_assessments
        WHERE postcode = '#{
          ActiveRecord::Base.sanitize_sql(postcode)
        }'"
      response = DomesticEnergyAssessment.connection.execute(sql)

      result = []
      response.each do |row|
        assessment_hash = to_hash(row.symbolize_keys)

        result.push(assessment_hash)
      end

      result
    end

    def search_by_assessment_id(assessment_id)
      sql =
        "SELECT
            scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
            type_of_assessment, total_floor_area, address_summary, current_energy_efficiency_rating,
            potential_energy_efficiency_rating, postcode, date_of_expiry,
            address_line1, address_line2, address_line3, address_line4, town
        FROM domestic_energy_assessments
        WHERE assessment_id = '#{
          ActiveRecord::Base.sanitize_sql(assessment_id)
        }'"

      response = DomesticEnergyAssessment.connection.execute(sql)

      result = []
      response.each do |row|
        assessment_hash = to_hash(row.symbolize_keys)

        result.push(assessment_hash)
      end

      result
    end

    def search_by_street_name_and_town(street_name, town)
      sql =
        "SELECT
            scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
            type_of_assessment, total_floor_area, address_summary, current_energy_efficiency_rating,
            potential_energy_efficiency_rating, postcode, date_of_expiry,
            address_line1, address_line2, address_line3, address_line4, town
        FROM domestic_energy_assessments
        WHERE (address_line1 ILIKE '%#{
          ActiveRecord::Base.sanitize_sql(street_name)
        }' OR address_line2 ILIKE '%#{
          ActiveRecord::Base.sanitize_sql(street_name)
        }' OR address_line3 ILIKE '%#{
          ActiveRecord::Base.sanitize_sql(street_name)
        }') AND (town ILIKE '#{ActiveRecord::Base.sanitize_sql(town)}')"

      response = DomesticEnergyAssessment.connection.execute(sql)

      result = []
      response.each do |row|
        assessment_hash = to_hash(row.symbolize_keys)

        result.push(assessment_hash)
      end

      result
    end

    private

    def send_to_db(assessment_id, domestic_energy_assessment)
      existing_assessment =
        DomesticEnergyAssessment.find_by(assessment_id: assessment_id)

      if existing_assessment
        existing_assessment.update(domestic_energy_assessment)
      else
        DomesticEnergyAssessment.create(domestic_energy_assessment)
      end
    end

    def get_energy_rating_band(number)
      case number
      when 1..20
        'g'
      when 21..38
        'f'
      when 39..54
        'e'
      when 55..68
        'd'
      when 69..80
        'c'
      when 81..91
        'b'
      when 92..100
        'a'
      end
    end
  end
end
