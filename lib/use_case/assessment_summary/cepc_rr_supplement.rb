module UseCase
  module AssessmentSummary
    class CepcRrSupplement < UseCase::AssessmentSummary::Supplement
      def related_cert_energy_band!(hash)
        related_cert =
          UseCase::AssessmentSummary::Fetch.new.execute(
            hash[:related_certificate],
          )

        hash[:energy_band_from_related_certificate] =
          (related_cert[:current_energy_efficiency_band] if related_cert)
      rescue StandardError => e
        hash[:energy_band_from_related_certificate] = nil
      end

      def related_party_disclosure!(hash)
        related_certificate =
          UseCase::AssessmentSummary::Fetch.new.execute(hash[:related_certificate])

        hash[:related_party_disclosure] =
          (related_certificate[:related_party_disclosure] if related_certificate)
      rescue StandardError => e
        hash[:related_party_disclosure] = nil
      end

      def add_data!(hash)
        registered_by!(hash)
        related_assessments!(hash)
        related_cert_energy_band!(hash)
        related_party_disclosure!(hash)

        hash
      end
    end
  end
end
