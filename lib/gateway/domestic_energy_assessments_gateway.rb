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
          certificate_id: self[:certificate_id],
          address_summary: self[:address_summary]
        }
      end
    end

    def fetch(certificate_id)
      energy_assessment = DomesticEnergyAssessment.find_by({ certificate_id: certificate_id })
      energy_assessment ? energy_assessment.to_hash : nil
    end

    def insert_or_update(certificate_id, assessment_body)
      domestic_energy_assessment = assessment_body.dup
      domestic_energy_assessment[:certificate_id] = certificate_id

      existing_assessment =
        DomesticEnergyAssessment.find_by(certificate_id: certificate_id)

      if existing_assessment
        existing_assessment.update(domestic_energy_assessment)
      else
        DomesticEnergyAssessment.create(domestic_energy_assessment)
      end
    end
  end
end
