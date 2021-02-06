module Helper
  class XmlEnumsToOutput
    # These mirror the energy performance ratings as in the
    # EnergyEfficiencySummaryCode simpleType defined in EPC-Domains.xsd
    RATINGS = [
      "N/A",
      "Very Poor",
      "Poor",
      "Average",
      "Good",
      "Very Good",
    ].freeze

    # These mirror the built form codes as in the
    # SAP-BuiltFormCode simpleType defined in SAP-Domains.xsd
    BUILT_FORM = {
      "1" => "Detached",
      "2" => "Semi-Detached",
      "3" => "End-Terrace",
      "4" => "Mid-Terrace",
      "5" => "Enclosed End-Terrace",
      "6" => "Enclosed Mid-Terrace",
      "NR" => "Not Recorded",
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
  end
end
