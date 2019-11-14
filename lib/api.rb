require 'sinatra/base'
require 'helpers/toggles'

class AssessorService < Sinatra::Base
  def initialize(toggles = false)
    super

    @toggles = toggles || Toggles.new
  end

  get '/' do
    'Hello world!'
  end

  get '/healthcheck' do
    status 200
  end
end