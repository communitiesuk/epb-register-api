class PostcodesGatewayStub
  def initialize(result)
    @result = result
  end

  def fetch(*)
    @result
  end
end
