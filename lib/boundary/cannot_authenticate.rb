module Boundary
  class CannotAuthenticate < Boundary::TerminableError
    def initialize(_msg = nil)
      super(<<~MESSAGE.strip)
        Failed to authenticate with the api
      MESSAGE
    end
  end
end
