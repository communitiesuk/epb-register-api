module Gateway
  class SchemesGateway
    class Scheme < ActiveRecord::Base
      def to_hash
        { scheme_id: self[:id], name: self[:name] }
      end
    end

    def all
      Scheme.all.map(&:to_hash)
    end

    def add(name)
      Scheme.create(name: name)
    end
  end
end
