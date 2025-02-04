module UseCase
  module AssessmentSummary
    class SapSupplement < UseCase::AssessmentSummary::Supplement
      def add_data!(hash, method = "to_hash")
        set_assessor!(hash, method)
        related_assessments!(hash)
        add_country_name!(hash)
        hash
      end
    end
  end
end
