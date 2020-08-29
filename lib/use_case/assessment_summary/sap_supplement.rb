module UseCase
  module AssessmentSummary
    class SapSupplement < UseCase::AssessmentSummary::Supplement
      def add_data!(hash)
        set_assessor!(hash)
        related_assessments!(hash)
        hash
      end
    end
  end
end
