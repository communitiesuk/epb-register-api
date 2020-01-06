class SchemesGatewayFake
  attr_writer :schemes

  def initialize
    @schemes = {}
  end

  def all
    @schemes
  end
end
