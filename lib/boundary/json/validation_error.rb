module Boundary
  module Json
    class ValidationError < Boundary::Json::Error
      attr_reader :failed_properties

      def initialize(msg = nil, failed_properties: [])
        super(<<~MSG.strip)
          JSON failed schema validation. Error: #{msg}
        MSG
        @failed_properties = failed_properties
      end
    end
  end
end
