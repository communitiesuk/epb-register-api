module Gateway
  class SchemesGateway
    class Scheme < ActiveRecord::Base; end

    def all
      Scheme.all.map { |s| { scheme_id: s[:id], name: s[:name] } }
    end

    def add(name)
      Scheme.create(name: name)
    end
  end
end
