module Gateway
  class SchemesGateway
    class DuplicateSchemeException < StandardError; end

    class Scheme < ActiveRecord::Base
      def to_hash
        { scheme_id: self[:id], name: self[:name], active: self[:active] }
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
    rescue StandardError => e
      case e
      when PG::UniqueViolation, ActiveRecord::RecordNotUnique
        raise DuplicateSchemeException
      else
        raise
      end
    end
  end
end
