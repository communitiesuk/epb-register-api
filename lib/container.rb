require "sinatra/activerecord"

class Container
  def initialize
    validate_and_lodge_assessment_use_case =
      UseCase::ValidateAndLodgeAssessment.new

    @objects = {
      validate_and_lodge_assessment_use_case:
        validate_and_lodge_assessment_use_case,
    }
  end

  def get_object(key)
    @objects[key]
  end
end
