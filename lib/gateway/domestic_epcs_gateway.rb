module Gateway
  class DomesticEpcsGateway
    class DomesticEpc < ActiveRecord::Base
      def to_hash
        {
            date_of_assessment: self[:date_of_assessment].strftime('%Y-%m-%d'),
            date_of_certificate: self[:date_of_certificate].strftime('%Y-%m-%d'),
            dwelling_type: self[:dwelling_type],
            type_of_assessment: self[:type_of_assessment],
            total_floor_area: self[:total_floor_area],
            certificate_id: self[:certificate_id]
        }
      end
    end

    def fetch(certificate_id)
      epc = DomesticEpc.find_by({certificate_id: certificate_id})
      epc ? epc.to_hash : nil
    end

    def insert_or_update(certificate_id, epc_body)
      domestic_epc = epc_body.dup
      domestic_epc[:certificate_id] = certificate_id

      existing_domestic_epc = DomesticEpc.find_by(
          certificate_id: certificate_id
      )

      if existing_domestic_epc
        existing_domestic_epc.update(domestic_epc)
      else
        DomesticEpc.create(domestic_epc)
      end
    end
  end
end
