module LodgementRules
  class DomesticCommon
    def self.method_or_nil(adapter, method)
      adapter.send(method)
    rescue NoMethodError
      nil
    end

    RULES = [
      {
        name: "MUST_HAVE_HABITABLE_ROOMS",
        title:
          '"Habitable-Room-Count" must be an integer and must be greater than or equal to 1',
        test: lambda do |adapter|
          habitable_room_count = method_or_nil(adapter, :habitable_room_count)
          if habitable_room_count.nil?
            return true
          end

          begin
            Integer(habitable_room_count) >= 1
          rescue StandardError
            return false
          end
        end,
      },
      {
        name: "RATINGS_MUST_BE_POSITIVE",
        title:
          '"Energy-Rating-Current", "Energy-Rating-Potential", "Environmental-Impact-Current" and "Environmental-Impact-Potential" must be greater than 0',
        test: lambda do |adapter|
          ratings = [
              method_or_nil(adapter, :energy_rating_current),
              method_or_nil(adapter, :energy_rating_potential),
              method_or_nil(adapter, :environmental_impact_current),
          ]
          ratings.compact.map(&:to_i).select{|rating| rating <= 0}.empty?
        end,
      },
    ].freeze

    def validate(xml_adaptor)
      errors = RULES.reject { |rule| rule[:test].call(xml_adaptor) }

      errors.map { |error| { code: error[:name], title: error[:title] } }
    end
  end
end
