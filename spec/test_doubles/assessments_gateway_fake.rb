class AssessmentsGatewayFake
  attr_writer :domestic_energy_assessment

  def initialize
    @domestic_energy_assessment = nil
  end

  def fetch(*)
    @domestic_energy_assessment
  end
end
