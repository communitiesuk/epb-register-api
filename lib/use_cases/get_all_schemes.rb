require_relative '../gateways/schemes/schemes_gateway'

class GetAllSchemes
  def execute
    gateway = SchemesGateway.new
    schemes = gateway.all_schemes
    { schemes: schemes }
  end
end
