module UseCase
  module AssessmentSummary
    class AcReportSupplement < UseCase::AssessmentSummary::Supplement
      def add_data!(hash)
        registered_by!(hash)
        related_assessments!(hash)
        add_country_id!(hash)
        hash
      end
    end
  end
end
