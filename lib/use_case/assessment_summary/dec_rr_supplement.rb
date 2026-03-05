module UseCase
  module AssessmentSummary
    class DecRrSupplement < UseCase::AssessmentSummary::Supplement
      def related_cert_energy_band!(hash, method = "to_hash", is_scottish: false)
        related_cert =
          UseCase::AssessmentSummary::Fetch.new.execute(hash[:related_rrn], method, is_scottish: is_scottish)

        hash[:energy_band_from_related_certificate] =
          (
            if related_cert
              related_cert[:current_assessment][:energy_efficiency_band]
            end
          )
        hash
      rescue StandardError
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
