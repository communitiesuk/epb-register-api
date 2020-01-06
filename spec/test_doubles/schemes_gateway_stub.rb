class SchemesGatewayStub
  def initialize(result)
    @result = result
  end

  def all(*)
    @result
  end
end
