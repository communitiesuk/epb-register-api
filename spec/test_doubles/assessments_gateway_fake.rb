class AssessmentsGatewayFake
  attr_writer :domestic_energy_assessment

  def initialize
    @domestic_energy_assessment = nil
  end

  def search_by_assessment_id(*)
    [@domestic_energy_assessment]
  end
end
