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

    def add(scheme_body)
      Scheme.create(name: scheme_body[:name], active: scheme_body[:active])
    rescue StandardError => e
      case e
      when PG::UniqueViolation, ActiveRecord::RecordNotUnique
        raise DuplicateSchemeException
      else
        raise
      end
    end

    def update(id, scheme_body)
      scheme = Scheme.find_by(scheme_id: id)
      scheme.update(name: scheme_body[:name], active: scheme_body[:active])
    end
  end
end
