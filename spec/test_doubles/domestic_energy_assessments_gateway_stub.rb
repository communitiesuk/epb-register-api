class DomesticEnergyAssessmentsGatewayStub
  def initialize(result)
    @result = result
  end

  def search(*)
    @result
  end
end
