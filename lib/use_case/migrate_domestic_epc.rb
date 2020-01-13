module UseCase
  class MigrateDomesticEpc
    def execute(certificate_id, epc_body)
      epc_body[:certificate_id] = certificate_id
      epc_body
    end
  end
end
