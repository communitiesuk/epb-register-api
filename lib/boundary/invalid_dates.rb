module Boundary
  class InvalidDates < Boundary::TerminableError
    def initialize
      super(<<~MSG.strip)
        date_from cannot be greater than date_to
      MSG
    end
  end
end
