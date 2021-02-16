module Boundary
  class InvalidAssessment < Boundary::TerminableError
    def initialize(argument)
      super(<<~MSG.strip)
        Assessment type is not valid: #{argument}
      MSG
    end
  end
end
