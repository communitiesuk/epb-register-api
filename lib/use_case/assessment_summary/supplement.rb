module UseCase
  module AssessmentSummary
    class Supplement
      def registered_by!(hash)
        assessor_id = hash[:assessor][:scheme_assessor_id]
        assessor = Gateway::AssessorsGateway.new.fetch(assessor_id)

        hash[:assessor][:registered_by] = {
          name: assessor.registered_by_name,
          scheme_id: assessor.registered_by_id,
        }
      end
    end
  end
end
