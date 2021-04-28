module UseCase
  module AssessmentSummary
    class AcReportSupplement < UseCase::AssessmentSummary::Supplement
      def add_data!(hash)
        registered_by!(hash)
        related_assessments!(hash)
        hash
      end
    end
  end
end
