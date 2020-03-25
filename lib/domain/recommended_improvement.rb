module Domain
  class RecommendedImprovement
    attr_reader :sequence

    def initialize(assessment_id, sequence)
      @assessment_id = assessment_id
      @sequence = sequence
    end

    def to_record
      { sequence: @sequence, assessment_id: @assessment_id }
    end

    def to_hash
      { sequence: @sequence }
    end
  end
end
