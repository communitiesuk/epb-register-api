module Boundary
  module Json
    class ParseError < Boundary::Json::Error
      def initialize(msg = nil)
        super(<<~MSG.strip)
          JSON did not parse. Error: #{msg}
        MSG
      end
    end
  end
end
