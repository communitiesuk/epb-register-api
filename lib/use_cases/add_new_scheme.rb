require 'sinatra/base'
require_relative '../gateways/schemes/scheme'

class AddNewScheme
  def execute(name)
    @scheme = Scheme.create(name: 'CIBSE')
  end
end
