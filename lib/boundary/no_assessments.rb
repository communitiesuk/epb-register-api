module Boundary
  class NoAssessments < Boundary::TerminableError
    def initialize(argument)
      super(<<~MSG.strip)
        no assessments found for: #{argument}
      MSG
    end
  end
end
