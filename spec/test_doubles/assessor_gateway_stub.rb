class AssessorGatewayStub
  attr_reader :assessor

  def initialize(assessor = nil)
    @assessor = assessor
  end

  def fetch(*)
    @assessor
  end
end
