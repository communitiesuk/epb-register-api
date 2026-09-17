module Boundary
  class ArgumentMissing < Boundary::TerminableError
    def initialize(argument)
      super "A required argument is missing: #{argument}"
    end
  end
end
