require_relative '../gateways/schemes/schemes_gateway'

class AddNewScheme
  def execute(name)
    gateway = SchemesGateway.new
    gateway.add_scheme(name)
  end
end
