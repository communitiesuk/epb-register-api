module Helper
  class XmlEnumsToOutput
    RATINGS = [
      "N/A",
      "Very Good",
      "Good",
      "Average",
      "Poor",
      "Very Poor",
    ].freeze
    BUILT_FORM = {
      "1" => "Detached",
      "2" => "Semi-Detached",
      "3" => "End-Terrace",
      "4" => "Mid-Terrace",
      "5" => "Enclosed End-Terrace",
      "6" => "Enclosed Mid-Terrace",
      "NR" => "Not Recorded",
    }.freeze
    ENERGY_TARIFF = {
      "1" => "standard tariff",
      "2" => "off-peak 7 hour",
      "3" => "off-peak 10 hour",
      "4" => "24 hour",
      "ND" => "not applicable",
    }.freeze

    def self.xml_value_to_string(number)
      BUILT_FORM[number]
    end

    def self.energy_rating_string(input)
      if input.is_a?(Array)
        array = []
        input.each do |input|
          number = input.to_i
          array << (number > RATINGS.length ? "N/A" : RATINGS[number])
        end
        array.join ", "
      else
        number = input.to_i
        number > RATINGS.length ? "N/A" : RATINGS[number]
      end
    end

    def self.energy_tariff(value)
      if !ENERGY_TARIFF.key?(value)
        ENERGY_TARIFF["ND"]
      else
        ENERGY_TARIFF[value]
      end
    end
  end
end
