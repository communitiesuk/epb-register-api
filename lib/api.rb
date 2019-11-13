require 'sinatra/base'

class AssessorService < Sinatra::Base
  get '/' do
    'Hello world!'
  end

  get '/healthcheck' do
    200
  end
end