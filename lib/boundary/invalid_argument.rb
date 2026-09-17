module Boundary
  class InvalidArgument < Boundary::TerminableError
    def initialize(argument)
      super "A required argument is is invalid: #{argument}"
    end
  end
end
