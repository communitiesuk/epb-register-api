module Boundary
  class InvalidDate < Boundary::TerminableError
    def initialize
      super(<<~MSG.strip)
        not a valid date
      MSG
    end
  end
end
