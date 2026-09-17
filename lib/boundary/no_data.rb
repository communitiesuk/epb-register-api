module Boundary
  class NoData < Boundary::TerminableError
    def initialize(argument)
      super "no data to be saved for: #{argument}"
    end
  end
end
