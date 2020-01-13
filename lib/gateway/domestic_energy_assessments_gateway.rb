module Gateway
  class DomesticEnergyAssessmentsGateway
    class DomesticEnergyAssessment < ActiveRecord::Base
      def to_hash
        {
          date_of_assessment: self[:date_of_assessment].strftime('%Y-%m-%d'),
          date_registered: self[:date_registered].strftime('%Y-%m-%d'),
          dwelling_type: self[:dwelling_type],
          type_of_assessment: self[:type_of_assessment],
          total_floor_area: self[:total_floor_area],
          assessment_id: self[:assessment_id],
          address_summary: self[:address_summary]
        }
      end
    end

    def fetch(assessment_id)
      energy_assessment = DomesticEnergyAssessment.find_by({ assessment_id: assessment_id })
      energy_assessment ? energy_assessment.to_hash : nil
    end

    def insert_or_update(assessment_id, assessment_body)
      domestic_energy_assessment = assessment_body.dup
      domestic_energy_assessment[:assessment_id] = assessment_id

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
