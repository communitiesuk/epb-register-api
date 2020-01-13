module UseCase
  class MigrateDomesticEpc
    def initialize(domestic_epcs_gateway)
      @domestic_epcs_gateway = domestic_epcs_gateway
    end

    def execute(certificate_id, epc_body)
      @domestic_epcs_gateway.insert_or_update(certificate_id, epc_body)

      epc_body[:certificate_id] = certificate_id
      epc_body
    end
  end
end
