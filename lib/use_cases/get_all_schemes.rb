require 'sinatra/base'
require_relative '../gateways/schemes/scheme'

class GetAllSchemes
  def execute
    @schemes = Scheme.all
    { schemes: @schemes }
  end
end
