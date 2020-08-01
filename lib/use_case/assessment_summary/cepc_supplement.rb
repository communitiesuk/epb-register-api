module UseCase
  module AssessmentSummary
    class CepcSupplement < UseCase::AssessmentSummary::Supplement
      def add_data!(hash)
        registered_by!(hash)

        related_assessments =
          Gateway::RelatedAssessmentsGateway.new.by_address_id hash[:address][
                                                                 :address_id
                                                               ]

        hash[:related_assessments] = related_assessments

        hash
      end
    end
  end
end
