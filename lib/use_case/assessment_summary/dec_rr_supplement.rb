module UseCase
  module AssessmentSummary
    class DecRrSupplement < UseCase::AssessmentSummary::Supplement
      def related_cert_energy_band!(hash)
        related_cert =
          UseCase::AssessmentSummary::Fetch.new.execute(hash[:related_rrn])

        hash[:energy_band_from_related_certificate] =
          (
            if related_cert
              related_cert[:current_assessment][:energy_efficiency_band]
            end
          )
      rescue StandardError => e
        pp e
        hash[:energy_band_from_related_certificate] = nil
      end

      def add_data!(hash)
        registered_by!(hash)
        related_assessments!(hash)
        related_cert_energy_band!(hash)
        hash
      end
    end
  end
end
