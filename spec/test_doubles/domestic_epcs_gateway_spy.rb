class DomesticEpcsGatewaySpy
  attr_reader :certificate_saved, :certificate_id_saved

  def insert_or_update(certificate_id, epc_body)
    @certificate_saved = epc_body
    @certificate_id_saved = certificate_id
    @certificate_to_return
  end
end
