module Boundary
  class NoAssessments < Boundary::TerminableError
    def initialize(argument)
      super "no assessments found for: #{argument}"
    end
  end
end
