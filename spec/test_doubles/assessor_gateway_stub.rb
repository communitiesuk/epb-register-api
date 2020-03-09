class AssessorGatewayStub
  attr_reader :assessor

  def initialize(assessor = {})
    @assessor = assessor
  end

  def fetch(*)
    @assessor
  end
end
