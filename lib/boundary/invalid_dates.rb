module Boundary
  class InvalidDates < Boundary::TerminableError
    def initialize
      super "date_from cannot be greater than date_to"
    end
  end
end
