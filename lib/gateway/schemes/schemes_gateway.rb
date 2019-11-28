class SchemesGateway

  class Scheme < ActiveRecord::Base

  end

  def all_schemes
    Scheme.all.map do |s|
      {
        scheme_id: s.id,
        name: s.name
      }
    end
  end

  def add_scheme(name)
    Scheme.create(name: name)
  end
end