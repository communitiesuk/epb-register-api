module UseCase
  class ValidateAndLodgeAssessment
    def initialize(validate_lodgement_use_case, lodge_assessment_use_case)
      @validate_lodgement_use_case = validate_lodgement_use_case
      @lodge_assessment_use_case = lodge_assessment_use_case
    end

    def execute
      @validate_lodgement_use_case.execute
      @lodge_assessment_use_case.execute
    end
  end
end
