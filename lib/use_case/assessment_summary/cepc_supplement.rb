module UseCase
  module AssessmentSummary
    class CepcSupplement < UseCase::AssessmentSummary::Supplement

      def add_data!(hash)
        assessor_id = hash[:assessor][:scheme_assessor_id]
        assessor = Gateway::AssessorsGateway.new.fetch(assessor_id)

        hash[:assessor][:registered_by] = {
            name: assessor.registered_by_name,
            scheme_id: assessor.registered_by_id,
        }

        related_assessments =
            Gateway::RelatedAssessmentsGateway.new.by_address_id hash[
                                                                     :address
                                                                 ][
                                                                     :address_id
                                                                 ]

        hash[:related_assessments] = related_assessments

        hash
      end
    end
  end
end
