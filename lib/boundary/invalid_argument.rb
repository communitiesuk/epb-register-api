module Boundary
  class InvalidArgument < Boundary::TerminableError
    def initialize(argument)
      super(<<~MSG.strip)
        A required argument is is invalid: #{argument}
      MSG
    end
  end
end
