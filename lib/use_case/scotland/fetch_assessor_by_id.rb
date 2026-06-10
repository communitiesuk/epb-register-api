module UseCase
  module Scotland
    class FetchAssessorById
      def initialize(gateway)
        @gateway = gateway
      end

      def execute(scheme_assessor_id:)
        assessor = @gateway.fetch(scheme_assessor_id)

        unless assessor
          raise Boundary::AssessorNotFoundException
        end

        assessor.scottish_assessor
      end
    end
  end
end
