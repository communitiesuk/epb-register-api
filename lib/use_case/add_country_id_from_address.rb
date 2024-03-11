module UseCase
  class AddCountryIdFromAddress
    def initialize(country_gateway)
      @countries = country_gateway.fetch_countries
    end

    def execute(lodgement_domain:, country_domain:)
      begin
        country_id = if lodgement_domain.country_code.nil? && !country_domain.country_codes.any?
                       get_unknown_country
                     elsif (lodgement_domain.is_new_rdsap? || lodgement_domain.is_new_sap?) && country_domain.on_border?
                       get_country_id(lodgement_domain.country_code)
                     else
                       country_domain.country_codes.any? ? get_country_id_by_address_base_code(country_domain.country_codes) : get_country_id(lodgement_domain.country_code)
                     end
      rescue NoMethodError
        country_id = get_unknown_country
      end
      lodgement_domain.add_country_id_to_data(country_id)
    end

  private

    def get_unknown_country
      get_country_id("UKN")
    end

    def get_country_id(value)
      @countries.find { |country| country[:country_code] == value }[:country_id]
    rescue NoMethodError
      nil
    end

    def get_country_id_by_address_base_code(value)
      @countries.find { |country| country[:address_base_country_code] == value.map(&:to_s).to_s }[:country_id]
    end
  end
end
