# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/hash/conversions"

module Domain
  class Lodgement
    attr_reader :raw_data

    def initialize(data, schema_name)
      @raw_data = data
      @schema_name = schema_name.to_sym
      @assessment_data = []
      @xml = Nokogiri.XML(@raw_data) { |config| config.huge.strict }
      @xml.remove_namespaces!
      set_data
    end

    def fetch_data
      @assessment_data
    end

    def add_country_id_to_data(id)
      @assessment_data.each { |report| report[:country_id] = id }
    end

    def fetch_country_id
      fetch_data[0][:country_id]
    end

    def country_code
      @assessment_data.first[:country_code]
    end

    def schema_version
      @schema_name.to_s.split("-").last.to_f
    end

    def is_new_rdsap?
      @schema_name.to_s.include?("RdSAP") && schema_version > 20
    end

    def is_new_sap?
      @schema_name.to_s.match?(/^SAP/) && schema_version > 18
    end

    def is_sap_17_or_18?
      @schema_name.to_s.match?(/^SAP/) && schema_version >= 17 && schema_version < 19 && !@schema_name.to_s.match?(/NI/)
    end

  private

    def set_data
      rrns = @xml.xpath("//RRN").map(&:text)

      rrns.each do |rrn|
        report =
          ViewModel::Factory
            .new
            .create(@raw_data, @schema_name.to_s, rrn)
            .to_hash
        report[:raw_data] = @raw_data
        @assessment_data << report
      end
    end

    def get_country_id(country_domain)
      xml_country_code = @xml.xpath("//Country-Code").inner_text

      return country_domain.uk_country_code(xml_country_code) if (is_new_rdsap? || is_new_sap?) && country_domain.on_border?

      country_domain.country_id
    end
  end
end
