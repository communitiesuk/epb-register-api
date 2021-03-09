module Boundary
  class OpenDataEmpty < Boundary::TerminableError
    def initialize
      super(<<~MSG.strip)
        No data provided for export
      MSG
    end
  end
end
