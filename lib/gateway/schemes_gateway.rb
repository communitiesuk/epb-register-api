module Gateway
  class SchemesGateway
    class DuplicateSchemeException < Exception; end

    class Scheme < ActiveRecord::Base
      def to_hash
        { scheme_id: self[:id], name: self[:name] }
      end
    end

    def all
      Scheme.all.map(&:to_hash)
    end

    def exists?(scheme_id)
      Scheme.exists?(scheme_id)
    end

    def add(name)
      Scheme.create(name: name)
    rescue Exception => e
      case e
      when PG::UniqueViolation, ActiveRecord::RecordNotUnique
        raise DuplicateSchemeException
      else
        raise e
      end
    end
  end
end
