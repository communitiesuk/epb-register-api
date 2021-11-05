module Boundary
  module Json
    class ValidationError < Boundary::Json::Error
      def initialize(msg = nil)
        super(<<~MSG.strip)
          JSON failed schema validation. Error: #{msg}
        MSG
      end
    end
  end
end
