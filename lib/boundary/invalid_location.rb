module Boundary
  class InvalidLocation < Boundary::TerminableError
    def initialize(argument)
      super(<<~MSG.strip)
        #{argument}
      MSG
    end
  end
end
