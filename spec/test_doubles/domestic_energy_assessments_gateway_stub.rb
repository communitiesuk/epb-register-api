class DomesticEnergyAssessmentsGatewayStub
  def initialize(result)
    @result = result
  end

  def search_by_postcode(*)
    @result
  end
end
