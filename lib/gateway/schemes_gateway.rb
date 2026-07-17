module Gateway
  class SchemesGateway
    class DuplicateSchemeException < StandardError
    end

    class SchemeNotPresentException < StandardError
    end

    class Scheme < ActiveRecord::Base
      def to_hash
        { scheme_id: id, name: self[:name], active: self[:active], active_scotland: self[:active_scotland], active_eng_wls_nir: self[:active_eng_wls_nir] }
      end
    end

    def all
      Scheme.all.map(&:to_hash)
    end

    def exists?(scheme_id)
      id = Integer(scheme_id)

      Scheme.exists?(id)
    rescue ArgumentError, TypeError
      false
    end

    def add(scheme_body)
      Scheme.create(name: scheme_body[:name], active: scheme_body[:active], active_scotland: scheme_body[:active_scotland], active_eng_wls_nir: scheme_body[:active_eng_wls_nir])
    rescue PG::UniqueViolation, ActiveRecord::RecordNotUnique
      raise DuplicateSchemeException
    end

    def update(id, scheme_body)
      scheme = Scheme.find_by(scheme_id: id)
      if scheme.nil?
        raise SchemeNotPresentException
      end

      scheme.update(name: scheme_body[:name], active: scheme_body[:active], active_scotland: scheme_body[:active_scotland], active_eng_wls_nir: scheme_body[:active_eng_wls_nir])
    end

    def fetch_active
      ActiveRecord::Base.connection.exec_query(
        "SELECT scheme_id FROM schemes WHERE active = TRUE",
      ).map { |result| result["scheme_id"] }
    end
  end
end
