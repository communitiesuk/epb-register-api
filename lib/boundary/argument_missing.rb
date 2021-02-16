module Boundary
  class ArgumentMissing < Boundary::TerminableError
    def initialize(argument)
      super(<<~MSG.strip)
        A required argument is missing: #{argument}
      MSG
    end
  end
end
