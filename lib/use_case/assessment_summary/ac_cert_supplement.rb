module UseCase
  module AssessmentSummary
    class AcCertSupplement < UseCase::AssessmentSummary::Supplement
      def related_party_disclosure!(hash)
        related_report =
          UseCase::AssessmentSummary::Fetch.new.execute(
            hash[:related_rrn],
          )

        hash[:related_party_disclosure] =
          (related_report[:related_party_disclosure] if related_report)
      rescue StandardError => e
        hash[:related_party_disclosure] = nil
      end

      def add_data!(hash)
        related_party_disclosure!(hash)

        hash
      end
    end
  end
end
