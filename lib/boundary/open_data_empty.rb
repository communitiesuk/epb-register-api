module Boundary
  class OpenDataEmpty < Boundary::TerminableError
    def initialize(argument = '')
      super(<<~MSG.strip)
        No data provided for export  #{argument}
      MSG
    end
  end
end
