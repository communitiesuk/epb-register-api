require 'sinatra/base'
require 'helpers/unleash'

class AssessorService < Sinatra::Base
  get '/' do
    'Hello world!'
  end

  get '/healthcheck' do
    status 200
  end
end