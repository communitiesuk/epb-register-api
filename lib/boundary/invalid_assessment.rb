module Boundary
  class InvalidAssessment < Boundary::TerminableError
    def initialize(argument)
      super "Assessment type is not valid: #{argument}"
    end
  end
end
