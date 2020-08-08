module LodgementRules
  class DomesticCommon
    def self.method_or_nil(adapter, method)
      adapter.send(method)
    rescue NoMethodError
      nil
    end

    RULES = [
    ].freeze

    def validate(xml_adaptor)
      errors = RULES.reject { |rule| rule[:test].call(xml_adaptor) }

      errors.map { |error| { code: error[:name], title: error[:title] } }
    end
  end
end
