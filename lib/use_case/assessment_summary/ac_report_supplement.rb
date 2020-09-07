module UseCase
  module AssessmentSummary
    class AcReportSupplement < UseCase::AssessmentSummary::Supplement
      def add_data!(hash)
        registered_by!(hash)
        hash
      end
    end
  end
end
