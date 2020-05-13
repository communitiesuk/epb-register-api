class AssessmentsGatewayStub
  def initialize(result)
    @result = result
  end

  def search_by_postcode(*)
    @result
  end

  def search_by_assessment_id(*)
    @result
  end

  def search_by_street_name_and_town(*)
    @result
  end
end
