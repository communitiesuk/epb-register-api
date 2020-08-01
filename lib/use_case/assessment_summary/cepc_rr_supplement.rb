module UseCase
  module AssessmentSummary
    class CepcRrSupplement < UseCase::AssessmentSummary::Supplement

      def add_data!(hash)
        assessor_id = hash[:assessor][:scheme_assessor_id]
        assessor = Gateway::AssessorsGateway.new.fetch(assessor_id)

        hash[:assessor][:registered_by] = {
            name: assessor.registered_by_name,
            scheme_id: assessor.registered_by_id,
        }

        hash
      end
    end
  end
end
