require 'sinatra/activerecord'

class SchemesGateway

  class Scheme < ActiveRecord::Base

  end

  def all_schemes
    Scheme.all
  end

  def add_scheme(name)
    Scheme.create(name: name)
  end
end