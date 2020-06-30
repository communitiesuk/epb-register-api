module Domain
  class RelatedAssessment
    attr_accessor :related_assessments

    def initialize(related_assessments:)
      @related_assessments = related_assessments
    end
  end
end
