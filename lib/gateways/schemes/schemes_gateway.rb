require 'sinatra/activerecord'

class SchemesGateway

  class Scheme < ActiveRecord::Base

  end

  def all_schemes
    Scheme.all.map do |s|
      { name: s.name,
        scheme_id: s.id }
    end
  end

  def add_scheme(name)
    Scheme.create(name: name)
  end
end