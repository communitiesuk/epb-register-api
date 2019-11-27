
class GetAllSchemes
  def initialize(gateway)
    @gateway = gateway
  end

  def execute
    schemes = @gateway.all_schemes
    { schemes: schemes }
  end
end
