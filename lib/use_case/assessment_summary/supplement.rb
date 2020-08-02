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

      def related_assessments!(hash)
        related_assessments =
          Gateway::RelatedAssessmentsGateway.new.by_address_id hash[:address][
                                                                 :address_id
                                                               ]

        other_assessments_without_self =
          related_assessments.filter do |assessment|
            assessment.to_hash[:assessment_id] != hash[:assessment_id]
          end

        hash[:related_assessments] = other_assessments_without_self
      end
    end
  end
end
