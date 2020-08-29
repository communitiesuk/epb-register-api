module UseCase
  module AssessmentSummary
    class SapSupplement < UseCase::AssessmentSummary::Supplement
      def add_data!(hash)
        set_assessor!(hash)
        related_assessments!(hash)
        add_green_deal!(hash)
        hash
      end
    end
  end
end
