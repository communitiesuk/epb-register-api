module UseCase
  module AssessmentSummary
    class RdSapSupplement < UseCase::AssessmentSummary::Supplement
      def add_data!(hash)
        set_assessor!(hash)
        related_assessments!(hash)
        add_green_deal!(hash)
        add_country_id!(hash)
        add_country_name!(hash)
        hash
      end
    end
  end
end
