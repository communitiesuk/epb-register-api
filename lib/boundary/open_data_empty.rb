module Boundary
  class OpenDataEmpty < Boundary::TerminableError
    def initialize(argument = "")
      super "No data provided for export #{argument}"
    end
  end
end
