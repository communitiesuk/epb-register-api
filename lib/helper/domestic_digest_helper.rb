module Helper
  module DomesticDigestHelper
    def get_domestic_digest(rrn:)
      result = domestic_digest_gateway.fetch_by_rrn rrn
      return nil if result.nil?

      ViewModel::Factory.new.create(result["xml"], result["schema_type"], rrn).to_domestic_digest
    end

    def get_assessment_summary(rrn:)
      summary_use_case.execute(rrn)
    end

    def pluck_property_summary_descriptions(domestic_digest:, feature_type:)
      domestic_digest[:property_summary]
        .select { |feature| [feature_type, "#{feature_type}s"].include?(feature[:name]) } # descriptions in property summary can be called "wall" or "walls", or "window" or "windows" depending on whether SAP or RdSAP due to slight schema divergence here
        .map { |feature| feature[:description] }
    end

    def strip_england_and_wales_prefix(age_band)
      return nil if age_band.nil?

      england_and_wales_prefix = "England and Wales: "
      return age_band unless age_band.start_with? england_and_wales_prefix

      age_band[england_and_wales_prefix.length..]
    end

    def convert_to_big_decimal(node)
      return "" unless node

      BigDecimal(node, 0)
    end
  end
end
