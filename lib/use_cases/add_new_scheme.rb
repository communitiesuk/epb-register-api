require 'sinatra/base'
require_relative '../models/scheme'

class AddNewScheme
  def execute(name)
    @scheme = Scheme.create(name: 'CIBSE')
  end
end
