require 'sinatra/base'
require_relative 'helpers/toggles'

class AssessorService < Sinatra::Base
  attr_reader :toggles

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