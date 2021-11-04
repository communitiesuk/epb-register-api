module Boundary
  class NoData < Boundary::TerminableError
    def initialize(argument)
      super(<<~MSG.strip)
        no data to be saved for: #{argument}
      MSG
    end
  end
end
