require 'sinatra/base'
require_relative 'helpers/toggles'
require_relative './models/scheme'

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

  get '/schemes' do
    content_type :json

    @schemes = Scheme.all
    { 'schemes' => "#{@schemes.to_json}"}.to_json
  end
end
