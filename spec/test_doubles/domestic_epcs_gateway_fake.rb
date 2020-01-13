class DomesticEpcsGatewayFake
  attr_writer :domestic_epc

  def initialize
    @domestic_epc = nil
  end

  def fetch(*)
    @domestic_epc
  end
end
