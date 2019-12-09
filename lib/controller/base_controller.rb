require_relative '../helper/toggles'
require_relative '../container'
require 'sinatra/cross_origin'

module Controller
  class BaseController < Sinatra::Base
    attr_reader :toggles

    def initialize(toggles = false)
      super
      @json_helper = Helper::JsonHelper.new
      @toggles = toggles || Toggles.new
      @container = Container.new
    end

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
      also_reload 'lib/**/*.rb'
    end

    configure do
      enable :cross_origin
      set :protection, except: %i[remote_token]
    end

    before do
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Headers'] =
          'Content-Type, Cache-Control, Accept'
    end

  end
end
