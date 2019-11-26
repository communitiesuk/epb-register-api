require_relative 'dto/scheme'

class SchemesGateway
  def all_schemes
    Scheme.all
  end

  def add_scheme(name)
    Scheme.create(name: name)
  end
end