module Boundary
  class InvalidNiAssessment < Boundary::TerminableError
    def initialize(argument)
      super(<<~MSG.strip)
          #{argument}
      MSG
    end
  end
end
