module UseCase
  class MigrateDomesticEnergyAssessment
    SEQUENCE_ERROR = 'Sequences must contain 0 and be continuous'
    def initialize(domestic_energy_assessments_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
    end

    def check_improvements(improvements)
      sequences = improvements.map(&:sequence)

      raise ArgumentError.new(SEQUENCE_ERROR) unless sequences.include? 0

      unless sequences.sort.each_cons(2).all? { |x, y| y == x + 1 }
        raise ArgumentError.new(SEQUENCE_ERROR)
      end
    end

    def execute(migrate_domestic_energy_assessment_request)
      assessment = migrate_domestic_energy_assessment_request.to_domain
      check_improvements(assessment.recommended_improvements)

      @domestic_energy_assessments_gateway.insert_or_update(assessment)
      assessment
    end
  end
end
