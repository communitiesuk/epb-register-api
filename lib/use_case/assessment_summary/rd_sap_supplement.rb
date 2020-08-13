module UseCase
  module AssessmentSummary
    class RdSapSupplement < UseCase::AssessmentSummary::Supplement
      def add_data!(hash)
        set_assessor!(hash)
        related_assessments!(hash)
        hash[:related_assessments].push(
          {
            assessment_expiry_date: hash[:date_of_expiry],
            assessment_id: hash[:assessment_id],
            assessment_status: hash[:status],
            assessment_type: "RdSAP",
          },
        )
        add_green_deal!(hash)
        hash
      end
    end
  end
end
