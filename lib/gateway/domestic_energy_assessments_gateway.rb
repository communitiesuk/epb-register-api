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
        address_summary: assessment[:address_summary],
        current_energy_efficiency_rating:
          assessment[:current_energy_efficiency_rating],
        potential_energy_efficiency_rating:
          assessment[:potential_energy_efficiency_rating],
        postcode: assessment[:postcode],
        date_of_expiry: assessment[:date_of_expiry].strftime('%Y-%m-%d')
      }
    end

    def fetch(assessment_id)
      energy_assessment =
        DomesticEnergyAssessment.find_by({ assessment_id: assessment_id })
      energy_assessment ? energy_assessment.to_hash : nil
    end

    def insert_or_update(assessment_id, assessment_body)
      domestic_energy_assessment = assessment_body.dup
      domestic_energy_assessment[:assessment_id] = assessment_id
      current_rating =
        domestic_energy_assessment[:current_energy_efficiency_rating]
      potential_rating =
        domestic_energy_assessment[:potential_energy_efficiency_rating]

      if !(current_rating.is_a?(Integer) && current_rating.between?(1, 100))
        raise InvalidCurrentEnergyRatingException
      elsif !(
            potential_rating.is_a?(Integer) && potential_rating.between?(1, 100)
          )
        raise InvalidPotentialEnergyRatingException
      else
        send_to_db(assessment_id, domestic_energy_assessment)
      end
    end

    def search(query, postcode = true)
      sql =
        'SELECT
            assessment_id, date_of_assessment, date_registered, dwelling_type,
            type_of_assessment, total_floor_area, address_summary, current_energy_efficiency_rating,
            potential_energy_efficiency_rating, postcode, date_of_expiry
        FROM domestic_energy_assessments
        WHERE '

      if postcode
        sql += "postcode = '#{ActiveRecord::Base.sanitize_sql(query)}'"
      else
        sql += "assessment_id = '#{ActiveRecord::Base.sanitize_sql(query)}'"
      end

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
  end
end
