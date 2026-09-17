module Boundary
  class InvalidDate < Boundary::TerminableError
    def initialize
      super "not a valid date"
    end
  end
end
