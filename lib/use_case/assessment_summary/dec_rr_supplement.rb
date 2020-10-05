module UseCase
  module AssessmentSummary
    class DecRrSupplement < UseCase::AssessmentSummary::Supplement
      def add_data!(hash)
        registered_by!(hash)
        related_assessments!(hash)
        related_cert_energy_band!(hash)
        fix_expiry_date!(hash)
        hash
      end

    private

      def related_cert_energy_band!(hash)
        @related_cert ||=
          UseCase::AssessmentSummary::Fetch.new.execute(hash[:related_rrn])

        hash[:energy_band_from_related_certificate] =
          (
            if @related_cert
              @related_cert[:current_assessment][:energy_efficiency_band]
            end
          )
      rescue StandardError => _e
        hash[:energy_band_from_related_certificate] = nil
      end

      def fix_expiry_date!(hash)
        @related_cert ||=
          UseCase::AssessmentSummary::Fetch.new.execute(hash[:related_rrn])

        floor_area = @related_cert[:technical_information][:floor_area]
        expiry_date = Date.parse(@related_cert[:current_assessment][:date])

        expiry_date =
          if floor_area.to_i <= 1000
            expiry_date.next_year 10
          else
            expiry_date.next_year 7
          end

        hash[:date_of_expiry] = expiry_date.strftime("%F")
      rescue StandardError => _e
      end
    end
  end
end
