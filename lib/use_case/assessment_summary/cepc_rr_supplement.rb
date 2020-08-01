module UseCase
  module AssessmentSummary
    class CepcRrSupplement < UseCase::AssessmentSummary::Supplement
      def add_data!(hash)
        registered_by!(hash)
        related_assessments!(hash)
        hash
      end
    end
  end
end
