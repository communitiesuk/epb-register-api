module Boundary
  class OpenDataEmpty < Boundary::TerminableError
    def initialize(argument)
      super(<<~MSG.strip)
        No data provided from #{argument}
      MSG
    end
  end
end
