require 'sinatra/base'
require_relative '../models/scheme'

class GetAllSchemes
  def execute
    @schemes = Scheme.all
    { schemes: @schemes }
  end
end
